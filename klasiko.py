#!/usr/bin/env python3
"""
Markdown to PDF Converter
Converts Markdown files to styled PDF documents with traditional white paper formatting.
"""

import argparse
import os
import sys
import re
import base64
import time
from pathlib import Path

try:
    import markdown
except ImportError:
    print("Error: markdown library not found. Please install it with: pip install markdown")
    sys.exit(1)

try:
    from weasyprint import HTML, CSS
    from weasyprint.text.fonts import FontConfiguration
except ImportError:
    print("Error: WeasyPrint not found. Please install it with: pip install weasyprint")
    sys.exit(1)

# Check for optional Pygments (for code highlighting)
try:
    import pygments
    PYGMENTS_AVAILABLE = True
except ImportError:
    PYGMENTS_AVAILABLE = False
    print("Warning: Pygments not found. Code syntax highlighting will be disabled.")
    print("Install with: pip install Pygments")


def extract_title_from_markdown(markdown_content):
    """
    Extract the first H1 heading from Markdown content as the title.

    Args:
        markdown_content (str): Raw Markdown content

    Returns:
        str: Extracted title or None if no H1 found
    """
    # Match first H1 heading (# Title or Title\n====)
    match = re.search(r'^#\s+(.+)$', markdown_content, re.MULTILINE)
    if match:
        return match.group(1).strip()

    # Alternative H1 syntax (underline with ===)
    match = re.search(r'^(.+)\n=+\s*$', markdown_content, re.MULTILINE)
    if match:
        return match.group(1).strip()

    return None


def extract_front_matter(markdown_content):
    """
    Extract front matter from Markdown document including title, subtitles, and metadata.
    Only extracts H2/H3 if they appear immediately after H1 (before any content paragraphs).

    Args:
        markdown_content (str): Raw Markdown content

    Returns:
        dict: Dictionary containing 'title', 'h2', 'h3', and 'metadata' fields
    """
    front_matter = {
        'title': None,
        'h2': None,
        'h3': None,
        'metadata': []
    }

    lines = markdown_content.split('\n')
    i = 0

    # Extract H1 (Title)
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('# '):
            front_matter['title'] = line[2:].strip()
            i += 1
            break
        i += 1

    # Only look for H2/H3 in the immediate next few lines (before any content)
    content_started = False

    # Extract H2 (Subtitle) - only if it comes immediately after H1
    while i < len(lines) and i < 20:  # Look within first 20 lines after H1
        line = lines[i].strip()

        # If we hit content (non-empty, non-heading, non-metadata), stop looking for subtitles
        if line and not line.startswith('#') and not line.startswith('**') and not line.startswith('---'):
            content_started = True
            break

        if line.startswith('## ') and not content_started:
            front_matter['h2'] = line[3:].strip()
            i += 1
            break
        elif line.startswith('# '):  # Stop if we hit another H1
            break
        i += 1

    # Extract H3 (Sub-subtitle) - only if we found H2 and no content yet
    if front_matter['h2'] and not content_started:
        while i < len(lines) and i < 25:
            line = lines[i].strip()

            # Stop if we hit content
            if line and not line.startswith('#') and not line.startswith('**') and not line.startswith('---'):
                content_started = True
                break

            if line.startswith('### '):
                front_matter['h3'] = line[4:].strip()
                i += 1
                break
            elif line.startswith('# ') or line.startswith('## '):  # Stop if we hit another heading
                break
            i += 1

    # Extract metadata lines (bold key-value pairs like **Date:** value)
    while i < len(lines) and i < 50:  # Look within first 50 lines
        line = lines[i].strip()

        # Stop at horizontal rule or next major heading
        if line.startswith('---') or line.startswith('# '):
            break

        # Match patterns like **Key:** Value or **Key**: Value
        metadata_match = re.match(r'\*\*([^*]+):\*\*\s*(.+)', line)
        if metadata_match:
            key = metadata_match.group(1).strip()
            value = metadata_match.group(2).strip()
            front_matter['metadata'].append({'key': key, 'value': value})

        i += 1

    return front_matter


def validate_logo_file(logo_path):
    """
    Validate logo file exists and is a supported format.

    Args:
        logo_path (str or Path): Path to logo file

    Returns:
        Path: Validated Path object

    Raises:
        FileNotFoundError: If file doesn't exist
        ValueError: If file format is not supported
    """
    logo_path = Path(logo_path)

    # Check existence
    if not logo_path.exists():
        raise FileNotFoundError(f"Logo file not found: {logo_path}")

    # Check extension
    valid_extensions = {'.png', '.jpg', '.jpeg', '.svg'}
    if logo_path.suffix.lower() not in valid_extensions:
        raise ValueError(
            f"Unsupported logo format: {logo_path.suffix}. "
            f"Supported formats: PNG, JPG, JPEG, SVG"
        )

    return logo_path


def encode_logo_to_base64(logo_path):
    """
    Convert logo file to base64 data URI for embedding in CSS.

    Args:
        logo_path (str or Path): Path to logo file

    Returns:
        str: Data URI string (e.g., 'data:image/png;base64,...')
    """
    logo_path = Path(logo_path)

    # Determine MIME type
    mime_types = {
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.svg': 'image/svg+xml',
    }

    suffix = logo_path.suffix.lower()
    mime_type = mime_types.get(suffix, 'image/png')

    # Read and encode
    with open(logo_path, 'rb') as f:
        encoded = base64.b64encode(f.read()).decode('utf-8')

    return f'data:{mime_type};base64,{encoded}'


def process_logo_argument(logo_path):
    """
    Process and validate logo argument, returning data URI.

    Args:
        logo_path (str or None): Path to logo file

    Returns:
        str or None: Base64 data URI or None if no logo
    """
    if not logo_path:
        return None

    try:
        # Validate file
        validated_path = validate_logo_file(logo_path)

        # Get file info
        size_mb = validated_path.stat().st_size / (1024 * 1024)

        # Warn if file is large
        if size_mb > 0.5:
            print(f"  Warning: Large logo file ({size_mb:.1f}MB). Consider optimizing for faster PDF generation.")

        # Encode to base64
        logo_data_uri = encode_logo_to_base64(validated_path)

        print(f"✓ Logo loaded: {validated_path.name} ({validated_path.suffix.upper()})")

        return logo_data_uri

    except FileNotFoundError as e:
        print(f"✗ Logo Error: {e}")
        sys.exit(1)
    except ValueError as e:
        print(f"✗ Logo Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Unexpected error loading logo: {e}")
        sys.exit(1)


def convert_markdown_to_html(markdown_file, enable_toc=False):
    """
    Convert Markdown file to HTML with proper extensions.

    Args:
        markdown_file (str): Path to the Markdown file
        enable_toc (bool): Whether to generate table of contents

    Returns:
        tuple: (html_content, markdown_content, md_instance)
    """
    try:
        with open(markdown_file, 'r', encoding='utf-8') as file:
            markdown_content = file.read()
    except UnicodeDecodeError as e:
        # Try alternative encoding if UTF-8 fails
        try:
            with open(markdown_file, 'r', encoding='latin-1') as file:
                markdown_content = file.read()
            print("Warning: File encoding detected as Latin-1, not UTF-8")
        except Exception as e:
            raise Exception(f"Error reading file with multiple encodings: {e}")
    except FileNotFoundError:
        raise FileNotFoundError(f"Markdown file not found: {markdown_file}")
    except Exception as e:
        raise Exception(f"Error reading Markdown file: {e}")

    # Build extensions list
    extensions = [
        'extra',           # Includes tables, fenced_code, and more
        'footnotes',       # Support for [^1] footnote references
        'toc',             # Table of contents support
    ]

    # Add codehilite only if Pygments is available
    if PYGMENTS_AVAILABLE:
        extensions.append('codehilite')

    # Configure TOC
    extension_configs = {}
    if enable_toc:
        extension_configs['toc'] = {
            'title': 'Table of Contents',
            'toc_depth': '2-3',
        }

    # Convert Markdown to HTML with extensions
    md = markdown.Markdown(extensions=extensions, extension_configs=extension_configs)
    html_content = md.convert(markdown_content)

    return html_content, markdown_content, md


def get_default_theme_css():
    """
    Return CSS for the default clean, professional theme.
    Original white paper styling with neutral colors.
    """
    return """
        @page {
            size: A4;
            margin: 2.5cm 2cm;

            @top-left {
                content: "•";
                font-size: 8pt;
                color: #666;
            }

            @top-center {
                content: "";
                font-size: 8pt;
                color: #666;
            }

            @top-right {
                content: "•";
                font-size: 8pt;
                color: #666;
            }

            @bottom-left {
                content: "•";
                font-size: 8pt;
                color: #666;
            }

            @bottom-center {
                content: "Page " counter(page);
                font-size: 8pt;
                color: #666;
                font-family: 'Times New Roman', 'DejaVu Serif', serif;
            }

            @bottom-right {
                content: "•";
                font-size: 8pt;
                color: #666;
            }
        }

        body {
            font-family: 'Times New Roman', 'DejaVu Serif', 'Noto Serif', Times, serif;
            font-size: 12pt;
            line-height: 1.6;
            color: #333;
            text-align: justify;
            margin: 0;
            padding: 0;
        }

        h1, h2, h3, h4, h5, h6 {
            font-family: Georgia, 'Times New Roman', Times, serif;
            font-weight: normal;
            color: #222;
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            page-break-after: avoid;
            break-after: avoid;
            page-break-inside: avoid;
            break-inside: avoid;
        }

        h1 {
            font-size: 18pt;
            text-align: center;
            margin-top: 2em;
            margin-bottom: 1.5em;
            border-bottom: 1px solid #ccc;
            padding-bottom: 0.5em;
        }

        h2 {
            font-size: 16pt;
            border-bottom: 1px solid #eee;
            padding-bottom: 0.3em;
            page-break-before: always;
            break-before: page;
        }

        /* First h2 after title should not force page break */
        .content > h2:first-child,
        h1 + h2,
        hr + h2 {
            page-break-before: avoid;
            break-before: avoid;
        }

        h3 {
            font-size: 14pt;
            font-style: italic;
        }

        h4, h5, h6 {
            font-size: 12pt;
            font-style: italic;
        }

        p {
            margin: 0 0 1em 0;
            orphans: 2;
            widows: 2;
        }

        blockquote {
            margin: 1em 2em;
            padding: 0.5em 1em;
            border-left: 3px solid #ccc;
            background-color: #f9f9f9;
            font-style: italic;
            color: #555;
        }

        code {
            font-family: 'Courier New', 'DejaVu Mono', 'Liberation Mono', Courier, monospace;
            font-size: 10pt;
            background-color: #f5f5f5;
            padding: 0.1em 0.3em;
            border-radius: 3px;
        }

        pre {
            font-family: 'Courier New', 'DejaVu Mono', 'Liberation Mono', Courier, monospace;
            font-size: 10pt;
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 3px;
            padding: 1em;
            overflow: auto;
            margin: 1em 0;
            page-break-inside: avoid;
        }

        pre code {
            background: none;
            padding: 0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1em 0;
            font-size: 11pt;
            page-break-inside: auto;
            break-inside: auto;
        }

        tr {
            page-break-inside: avoid;
            break-inside: avoid;
        }

        thead {
            display: table-header-group;
        }

        thead tr {
            page-break-after: avoid;
            break-after: avoid;
        }

        table.long-table {
            page-break-inside: auto;
        }

        table.long-table tr {
            page-break-inside: avoid;
            page-break-after: auto;
        }

        table.long-table thead {
            display: table-header-group;
        }

        table.long-table tfoot {
            display: table-footer-group;
        }

        th, td {
            border: 1px solid #ddd;
            padding: 0.5em;
            text-align: left;
            word-wrap: break-word;
        }

        th {
            background-color: #f5f5f5;
            font-weight: bold;
        }

        ul, ol {
            margin: 1em 0;
            padding-left: 2em;
        }

        li {
            margin: 0.3em 0;
        }

        a {
            color: #0066cc;
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1em auto;
            page-break-inside: avoid;
        }

        .toc {
            background-color: #f9f9f9;
            border: 1px solid #ddd;
            padding: 1.5em;
            margin: 2em 0 3em 0;
            page-break-after: always;
        }

        .toc-title {
            font-size: 16pt;
            font-weight: bold;
            margin-bottom: 1em;
            text-align: center;
        }

        .toc ul {
            list-style-type: none;
            padding-left: 0;
        }

        .toc li {
            margin: 0.5em 0;
            padding-left: 1em;
        }

        .toc a {
            color: #0066cc;
            text-decoration: none;
        }

        .footnote {
            font-size: 10pt;
            line-height: 1.4;
        }

        .footnote-ref {
            vertical-align: super;
            font-size: 0.8em;
            text-decoration: none;
        }

        .footnote-backref {
            text-decoration: none;
        }

        hr {
            border: none;
            border-top: 1px solid #ccc;
            margin: 2em 0;
        }

        h1, h2, h3 {
            page-break-after: avoid;
        }

        pre, img {
            page-break-inside: avoid;
        }

        .title-page {
            text-align: center;
            margin-top: 8cm;
            page-break-after: always;
        }

        .title-page h1 {
            border: none;
            margin-bottom: 0.5em;
            font-size: 22pt;
            font-weight: bold;
        }

        .title-page h2 {
            border: none;
            margin-top: 0.5em;
            margin-bottom: 0.5em;
            font-size: 16pt;
            font-weight: normal;
            color: #333;
        }

        .title-page h3 {
            border: none;
            margin-top: 0.3em;
            margin-bottom: 2em;
            font-size: 14pt;
            font-weight: normal;
            font-style: italic;
            color: #555;
        }

        .meta-info {
            color: #444;
            margin-top: 3em;
            font-size: 11pt;
            line-height: 1.8;
        }

        .meta-info p {
            margin: 0.3em 0;
        }

        .meta-info .meta-key {
            font-weight: bold;
        }
    """


def get_warm_theme_css():
    """
    Return CSS for the warm neutral theme with vintage typography.
    Warm tones, double borders, small-caps headings, generous spacing.
    """
    return """
        @page {
            size: A4;
            margin: 3cm 2.5cm;
            background-color: #FAF8F5;

            @top-left {
                content: "❦";
                font-size: 9pt;
                color: #9B8579;
            }

            @top-center {
                content: "";
            }

            @top-right {
                content: "❦";
                font-size: 9pt;
                color: #9B8579;
            }

            @bottom-left {
                content: "❦";
                font-size: 9pt;
                color: #9B8579;
            }

            @bottom-center {
                content: "– " counter(page) " –";
                font-size: 10pt;
                color: #3A3229;
                font-family: 'Palatino Linotype', 'Book Antiqua', Palatino, 'Garamond', Georgia, serif;
            }

            @bottom-right {
                content: "❦";
                font-size: 9pt;
                color: #9B8579;
            }
        }

        body {
            font-family: 'Palatino Linotype', 'Book Antiqua', Palatino, 'Garamond', Georgia, 'Times New Roman', serif;
            font-size: 11.5pt;
            line-height: 1.7;
            color: #3A3229;
            text-align: justify;
            margin: 0;
            padding: 0;
            background-color: #FAF8F5;
        }

        h1, h2, h3, h4, h5, h6 {
            font-family: 'Garamond', 'Palatino Linotype', 'Book Antiqua', Georgia, serif;
            font-weight: bold;
            color: #2D2520;
            margin-top: 1.8em;
            margin-bottom: 0.7em;
            page-break-after: avoid;
            break-after: avoid;
            page-break-inside: avoid;
            break-inside: avoid;
        }

        h1 {
            font-size: 22pt;
            text-align: center;
            margin-top: 2em;
            margin-bottom: 1.5em;
            border-top: 3px double #9B8579;
            border-bottom: 3px double #9B8579;
            padding-top: 0.6em;
            padding-bottom: 0.6em;
            font-variant: small-caps;
            letter-spacing: 1pt;
        }

        h2 {
            font-size: 17pt;
            border-bottom: 2px solid #D4C4B5;
            padding-bottom: 0.4em;
            font-variant: small-caps;
            page-break-before: always;
            break-before: page;
        }

        /* First h2 after title should not force page break */
        .content > h2:first-child,
        h1 + h2,
        hr + h2 {
            page-break-before: avoid;
            break-before: avoid;
        }

        h3 {
            font-size: 14pt;
            font-weight: bold;
            font-style: normal;
        }

        h4, h5, h6 {
            font-size: 12pt;
            font-weight: bold;
            font-style: normal;
        }

        p {
            margin: 0 0 1.2em 0;
            orphans: 2;
            widows: 2;
        }

        blockquote {
            margin: 1.5em 2.5em;
            padding: 0.8em 1.2em;
            border-left: 4px solid #9B8579;
            background-color: #F3EDE6;
            font-style: italic;
            color: #4A3F36;
            font-size: 11pt;
        }

        code {
            font-family: 'Courier New', 'DejaVu Mono', 'Liberation Mono', Courier, monospace;
            font-size: 10pt;
            background-color: #F3EDE6;
            color: #4A3F36;
            padding: 0.15em 0.4em;
            border-radius: 2px;
        }

        pre {
            font-family: 'Courier New', 'DejaVu Mono', 'Liberation Mono', Courier, monospace;
            font-size: 10pt;
            background-color: #F3EDE6;
            border: 1px solid #D4C4B5;
            border-radius: 2px;
            padding: 1em;
            overflow: auto;
            margin: 1.5em 0;
            page-break-inside: avoid;
        }

        pre code {
            background: none;
            padding: 0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.5em 0;
            font-size: 10.5pt;
            border: 2px solid #9B8579;
            page-break-inside: auto;
            break-inside: auto;
        }

        tr {
            page-break-inside: avoid;
            break-inside: avoid;
        }

        thead {
            display: table-header-group;
        }

        thead tr {
            page-break-after: avoid;
            break-after: avoid;
        }

        table.long-table {
            page-break-inside: auto;
        }

        table.long-table tr {
            page-break-inside: avoid;
            page-break-after: auto;
        }

        table.long-table thead {
            display: table-header-group;
        }

        table.long-table tfoot {
            display: table-footer-group;
        }

        th, td {
            border: 1px solid #D4C4B5;
            padding: 0.6em;
            text-align: left;
            word-wrap: break-word;
        }

        th {
            background-color: #E8DECE;
            color: #2D2520;
            font-weight: bold;
            font-variant: small-caps;
        }

        tr:nth-child(even) {
            background-color: #F3EDE6;
        }

        tr:nth-child(odd) {
            background-color: #FAF8F5;
        }

        ul, ol {
            margin: 1em 0;
            padding-left: 2.2em;
        }

        li {
            margin: 0.4em 0;
        }

        a {
            color: #8B6F47;
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1.5em auto;
            page-break-inside: avoid;
        }

        .toc {
            background-color: #F3EDE6;
            border: 2px solid #9B8579;
            padding: 1.8em;
            margin: 2.5em 0 3.5em 0;
            page-break-after: always;
        }

        .toc-title {
            font-size: 18pt;
            font-weight: bold;
            font-variant: small-caps;
            margin-bottom: 1.2em;
            text-align: center;
            color: #2D2520;
            letter-spacing: 0.5pt;
        }

        .toc ul {
            list-style-type: none;
            padding-left: 0;
        }

        .toc li {
            margin: 0.6em 0;
            padding-left: 1.2em;
        }

        .toc a {
            color: #8B6F47;
            text-decoration: none;
        }

        .footnote {
            font-size: 10pt;
            line-height: 1.5;
            color: #4A3F36;
        }

        .footnote-ref {
            vertical-align: super;
            font-size: 0.8em;
            text-decoration: none;
        }

        .footnote-backref {
            text-decoration: none;
        }

        hr {
            border: none;
            height: 2px;
            background: linear-gradient(to right, transparent, #9B8579 20%, #9B8579 80%, transparent);
            margin: 2.5em 0;
        }

        h1, h2, h3 {
            page-break-after: avoid;
        }

        pre, img {
            page-break-inside: avoid;
        }

        .title-page {
            text-align: center;
            margin-top: 10cm;
            page-break-after: always;
        }

        .title-page h1 {
            border: none;
            border-top: 4px double #9B8579;
            border-bottom: 4px double #9B8579;
            padding: 1.5em 3em;
            margin-bottom: 1.2em;
            font-size: 26pt;
            font-weight: bold;
            font-variant: small-caps;
            letter-spacing: 2pt;
            color: #2D2520;
        }

        .title-page h2 {
            border: none;
            margin-top: 1em;
            margin-bottom: 0.8em;
            font-size: 18pt;
            font-weight: normal;
            font-style: italic;
            font-variant: normal;
            color: #3A3229;
        }

        .title-page h3 {
            border: none;
            margin-top: 0.5em;
            margin-bottom: 2.5em;
            font-size: 15pt;
            font-weight: normal;
            font-style: italic;
            color: #6B5F54;
        }

        .meta-info {
            color: #4A3F36;
            margin-top: 3.5em;
            font-size: 11pt;
            line-height: 2;
        }

        .meta-info p {
            margin: 0.4em 0;
        }

        .meta-info .meta-key {
            font-weight: bold;
            font-variant: small-caps;
        }
    """


def get_rustic_theme_css():
    """
    Return CSS for the full rustic theme with aged paper aesthetic.
    Coffee browns, ornamental elements, maximum vintage character.
    """
    return """
        @page {
            size: A4;
            margin: 3cm 2.5cm;
            background-color: #F4ECD8;

            @top-left {
                content: "❧";
                font-size: 10pt;
                color: #8B7355;
            }

            @top-center {
                content: "• • •";
                font-size: 8pt;
                color: #A0826D;
                letter-spacing: 0.4em;
            }

            @top-right {
                content: "❧";
                font-size: 10pt;
                color: #8B7355;
            }

            @bottom-left {
                content: "❧";
                font-size: 10pt;
                color: #8B7355;
            }

            @bottom-center {
                content: "– " counter(page) " –";
                font-size: 10pt;
                color: #3D2B1F;
                font-family: 'Garamond', 'Palatino', Georgia, serif;
            }

            @bottom-right {
                content: "❧";
                font-size: 10pt;
                color: #8B7355;
            }
        }

        body {
            font-family: 'Palatino Linotype', 'Book Antiqua', Palatino, 'Garamond', Georgia, serif;
            font-size: 11.5pt;
            line-height: 1.7;
            color: #2B1F17;
            text-align: justify;
            margin: 0;
            padding: 0;
            background-color: #F4ECD8;
        }

        h1, h2, h3, h4, h5, h6 {
            font-family: 'Garamond', 'Palatino', Georgia, serif;
            font-weight: bold;
            color: #3D2B1F;
            margin-top: 2em;
            margin-bottom: 0.8em;
            page-break-after: avoid;
            break-after: avoid;
            page-break-inside: avoid;
            break-inside: avoid;
        }

        h1 {
            font-size: 24pt;
            text-align: center;
            margin-top: 2.5em;
            margin-bottom: 1.8em;
            border-top: 3px double #8B7355;
            border-bottom: 3px double #8B7355;
            padding: 1em 2em;
            font-variant: small-caps;
            letter-spacing: 1.5pt;
            position: relative;
        }

        h1::after {
            content: "✦";
            display: block;
            text-align: center;
            font-size: 16pt;
            color: #8B7355;
            margin-top: 0.6em;
        }

        h2 {
            font-size: 18pt;
            border-bottom: 2px solid #A0826D;
            padding-bottom: 0.5em;
            font-variant: small-caps;
            page-break-before: always;
            break-before: page;
        }

        /* First h2 after title should not force page break */
        .content > h2:first-child,
        h1 + h2,
        hr + h2 {
            page-break-before: avoid;
            break-before: avoid;
        }

        h3 {
            font-size: 14pt;
            font-weight: bold;
            font-style: normal;
            color: #4A3728;
        }

        h4, h5, h6 {
            font-size: 12pt;
            font-weight: bold;
            font-style: normal;
            color: #4A3728;
        }

        p {
            margin: 0 0 1.2em 0;
            orphans: 2;
            widows: 2;
        }

        blockquote {
            margin: 1.5em 3em;
            padding: 1em 1.5em;
            border-left: 5px solid #8B7355;
            border-right: 1px solid #C9B899;
            background-color: #EDE1CF;
            font-style: italic;
            color: #4A3728;
            font-size: 11pt;
            position: relative;
        }

        blockquote::before {
            content: "\\201C";
            font-size: 48pt;
            color: #A0826D;
            opacity: 0.3;
            position: absolute;
            left: 0.2em;
            top: -0.2em;
            font-family: Georgia, serif;
        }

        code {
            font-family: 'Courier New', 'DejaVu Mono', Courier, monospace;
            font-size: 10pt;
            background-color: #EDE1CF;
            color: #4A3728;
            padding: 0.15em 0.4em;
            border-radius: 2px;
        }

        pre {
            font-family: 'Courier New', 'DejaVu Mono', Courier, monospace;
            font-size: 10pt;
            background-color: #EDE1CF;
            border: 1px solid #C9B899;
            border-radius: 2px;
            padding: 1em;
            overflow: auto;
            margin: 1.5em 0;
            page-break-inside: avoid;
        }

        pre code {
            background: none;
            padding: 0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.5em 0;
            font-size: 10.5pt;
            border: 2px solid #8B7355;
            page-break-inside: auto;
            break-inside: auto;
        }

        tr {
            page-break-inside: avoid;
            break-inside: avoid;
        }

        thead {
            display: table-header-group;
        }

        thead tr {
            page-break-after: avoid;
            break-after: avoid;
        }

        table.long-table {
            page-break-inside: auto;
        }

        table.long-table tr {
            page-break-inside: avoid;
            page-break-after: auto;
        }

        table.long-table thead {
            display: table-header-group;
        }

        table.long-table tfoot {
            display: table-footer-group;
        }

        th, td {
            border: 1px solid #C9B899;
            padding: 0.6em;
            text-align: left;
            word-wrap: break-word;
        }

        th {
            background-color: #DDD0B8;
            color: #2B1F17;
            font-weight: bold;
            font-variant: small-caps;
        }

        tr:nth-child(even) {
            background-color: #EDE1CF;
        }

        tr:nth-child(odd) {
            background-color: #F4ECD8;
        }

        ul, ol {
            margin: 1em 0;
            padding-left: 2.2em;
        }

        li {
            margin: 0.4em 0;
        }

        a {
            color: #8B4513;
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1.5em auto;
            page-break-inside: avoid;
        }

        .toc {
            background-color: #EDE1CF;
            border: 2px solid #8B7355;
            padding: 2em;
            margin: 2.5em 0 4em 0;
            page-break-after: always;
        }

        .toc-title {
            font-size: 18pt;
            font-weight: bold;
            font-variant: small-caps;
            margin-bottom: 1.5em;
            text-align: center;
            color: #3D2B1F;
            letter-spacing: 0.8pt;
        }

        .toc ul {
            list-style-type: none;
            padding-left: 0;
        }

        .toc li {
            margin: 0.6em 0;
            padding-left: 1.2em;
        }

        .toc a {
            color: #8B4513;
            text-decoration: none;
        }

        .footnote {
            font-size: 10pt;
            line-height: 1.5;
            color: #4A3728;
        }

        .footnote-ref {
            vertical-align: super;
            font-size: 0.8em;
            text-decoration: none;
        }

        .footnote-backref {
            text-decoration: none;
        }

        hr {
            border: none;
            height: 2px;
            background: linear-gradient(to right, transparent, #8B7355 20%, #8B7355 80%, transparent);
            margin: 2.5em 0;
            position: relative;
        }

        hr::after {
            content: "❧";
            display: block;
            text-align: center;
            margin-top: -0.9em;
            background: #F4ECD8;
            width: 2em;
            margin-left: auto;
            margin-right: auto;
            color: #8B7355;
            font-size: 14pt;
        }

        h1, h2, h3 {
            page-break-after: avoid;
        }

        pre, img {
            page-break-inside: avoid;
        }

        .title-page {
            text-align: center;
            margin-top: 10cm;
            page-break-after: always;
        }

        .title-page h1 {
            border: none;
            border-top: 4px double #8B7355;
            border-bottom: 4px double #8B7355;
            padding: 1.8em 3em;
            margin-bottom: 1.5em;
            font-size: 28pt;
            font-weight: bold;
            font-variant: small-caps;
            letter-spacing: 2.5pt;
            color: #2B1F17;
        }

        .title-page h1::before {
            content: "✦  ✦  ✦";
            display: block;
            font-size: 14pt;
            color: #8B7355;
            margin-bottom: 0.8em;
            letter-spacing: 1em;
        }

        .title-page h1::after {
            content: "✦  ✦  ✦";
            display: block;
            font-size: 14pt;
            color: #8B7355;
            margin-top: 0.8em;
            letter-spacing: 1em;
        }

        .title-page h2 {
            border: none;
            margin-top: 1em;
            margin-bottom: 0.8em;
            font-size: 18pt;
            font-weight: normal;
            font-style: italic;
            font-variant: normal;
            color: #3D2B1F;
        }

        .title-page h3 {
            border: none;
            margin-top: 0.5em;
            margin-bottom: 3em;
            font-size: 15pt;
            font-weight: normal;
            font-style: italic;
            color: #6B5344;
        }

        .meta-info {
            color: #4A3728;
            margin-top: 4em;
            font-size: 11pt;
            line-height: 2;
        }

        .meta-info p {
            margin: 0.4em 0;
        }

        .meta-info .meta-key {
            font-weight: bold;
            font-variant: small-caps;
        }
    """


def generate_logo_css(logo_data_uri, logo_position='header', logo_size='medium'):
    """
    Generate CSS for logo placement in PDF.

    Args:
        logo_data_uri (str): Base64 data URI of the logo
        logo_position (str): Position - 'header', 'footer', 'both', 'watermark', 'title', 'all'
        logo_size (str): Size - 'small', 'medium', 'large'

    Returns:
        str: CSS string for logo styling
    """
    if not logo_data_uri:
        return ""

    # Define logo sizes (height in cm)
    sizes = {
        'small': {'header': '1cm', 'footer': '0.8cm', 'title': '4cm', 'watermark': '30%'},
        'medium': {'header': '1.5cm', 'footer': '1cm', 'title': '6cm', 'watermark': '40%'},
        'large': {'header': '2cm', 'footer': '1.2cm', 'title': '8cm', 'watermark': '50%'},
    }

    size = sizes.get(logo_size, sizes['medium'])
    logo_css = ""

    # Header logo (all pages except first)
    if logo_position in ['header', 'both', 'all']:
        logo_css += f"""
        @page {{
            @top-left {{
                content: " ";
                background-image: url('{logo_data_uri}');
                background-size: contain;
                background-repeat: no-repeat;
                background-position: left center;
                height: {size['header']};
                width: 3cm;
            }}
        }}

        @page :first {{
            @top-left {{
                content: none;
            }}
        }}
        """

    # Footer logo
    if logo_position in ['footer', 'both', 'all']:
        logo_css += f"""
        @page {{
            @bottom-right {{
                content: " ";
                background-image: url('{logo_data_uri}');
                background-size: contain;
                background-repeat: no-repeat;
                background-position: right center;
                height: {size['footer']};
                width: 2.5cm;
            }}
        }}
        """

    # Title page logo (HTML-based, CSS for styling)
    if logo_position in ['title', 'all']:
        logo_css += f"""
        .title-logo {{
            display: block;
            margin: 0 auto 2em auto;
            max-height: {size['title']};
            width: auto;
            page-break-after: avoid;
        }}
        """

    # Watermark (fixed positioned element)
    if logo_position in ['watermark', 'all']:
        logo_css += f"""
        .watermark {{
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            opacity: 0.08;
            z-index: -1;
            width: {size['watermark']};
            pointer-events: none;
        }}

        .watermark img {{
            width: 100%;
            height: auto;
        }}
        """

    return logo_css


def get_theme_css(theme='warm'):
    """
    Get CSS for the specified theme.

    Args:
        theme (str): Theme name - 'default', 'warm', or 'rustic'

    Returns:
        str: CSS string for the theme
    """
    themes = {
        'default': get_default_theme_css,
        'warm': get_warm_theme_css,
        'rustic': get_rustic_theme_css
    }

    theme_function = themes.get(theme, get_warm_theme_css)
    return theme_function()


def create_complete_html_document(html_content, title, toc_html=None, custom_css=None, metadata=None, front_matter=None, theme='warm', logo_data_uri=None, logo_placements=None):
    """
    Create a complete HTML document with CSS styling.

    Args:
        html_content (str): The main HTML content
        title (str): Document title
        toc_html (str): Optional table of contents HTML
        custom_css (str): Optional custom CSS to append
        metadata (dict): Optional PDF metadata (author, subject, keywords)
        front_matter (dict): Optional front matter extracted from document (h2, h3, metadata)
        theme (str): Visual theme - 'default', 'warm', or 'rustic'
        logo_data_uri (str): Optional base64-encoded logo data URI
        logo_placements (list): List of dicts with 'position' and 'size' keys for each logo placement

    Returns:
        str: Complete HTML document
    """
    # Get theme CSS
    theme_css = get_theme_css(theme)

    # Generate logo CSS for multiple placements
    logo_css = ""
    if logo_data_uri and logo_placements:
        for placement in logo_placements:
            logo_css += generate_logo_css(
                logo_data_uri,
                placement.get('position', 'header'),
                placement.get('size', 'medium')
            )

    css_style = f"""
    <style>
{theme_css}
{logo_css}
    </style>
    """

    # Add custom CSS if provided
    if custom_css:
        css_style += f"\n    <style>\n{custom_css}\n    </style>"
    
    # Build metadata tags
    meta_tags = ""
    if metadata:
        if metadata.get('author'):
            meta_tags += f'    <meta name="author" content="{metadata["author"]}">\n'
        if metadata.get('subject'):
            meta_tags += f'    <meta name="subject" content="{metadata["subject"]}">\n'
        if metadata.get('keywords'):
            meta_tags += f'    <meta name="keywords" content="{metadata["keywords"]}">\n'

    # Build TOC section
    toc_section = ""
    if toc_html:
        toc_section = f"""    <div class="toc">
        <div class="toc-title">Table of Contents</div>
        {toc_html}
    </div>
"""

    # Build title page content
    title_page_content = ""

    # Add logo to title page if requested
    if logo_data_uri and logo_placements:
        has_title_logo = any(p.get('position') in ['title', 'all'] for p in logo_placements)
        if has_title_logo:
            title_page_content += f'<img src="{logo_data_uri}" class="title-logo" alt="Company Logo">\n        '

    title_page_content += f"<h1>{title}</h1>\n"

    if front_matter:
        # Add H2 subtitle if present
        if front_matter.get('h2'):
            title_page_content += f"        <h2>{front_matter['h2']}</h2>\n"

        # Add H3 sub-subtitle if present
        if front_matter.get('h3'):
            title_page_content += f"        <h3>{front_matter['h3']}</h3>\n"

        # Add metadata section if present
        if front_matter.get('metadata') and len(front_matter['metadata']) > 0:
            title_page_content += '        <div class="meta-info">\n'
            for meta_item in front_matter['metadata']:
                key = meta_item['key']
                value = meta_item['value']
                title_page_content += f'            <p><span class="meta-key">{key}:</span> {value}</p>\n'
            title_page_content += '        </div>\n'

    # Add watermark div if requested
    watermark_html = ""
    if logo_data_uri and logo_placements:
        has_watermark = any(p.get('position') in ['watermark', 'all'] for p in logo_placements)
        if has_watermark:
            watermark_html = f'    <div class="watermark"><img src="{logo_data_uri}" alt=""></div>\n'

    complete_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
{meta_tags}{css_style}
</head>
<body>
{watermark_html}    <div class="title-page">
        {title_page_content}
    </div>
{toc_section}    {html_content}
</body>
</html>"""

    return complete_html


def convert_md_to_pdf(input_file, output_file, enable_toc=False, custom_css=None, metadata=None, theme='warm', logo_data_uri=None, logo_placements=None):
    """
    Convert a Markdown file to a styled PDF document.

    Args:
        input_file (str): Path to input Markdown file
        output_file (str): Path to output PDF file
        enable_toc (bool): Whether to generate table of contents
        custom_css (str): Path to custom CSS file or CSS string
        metadata (dict): PDF metadata (author, subject, keywords)
        theme (str): Visual theme - 'default', 'warm', or 'rustic'
        logo_data_uri (str): Optional base64-encoded logo data URI
        logo_placements (list): List of dicts with 'position' and 'size' keys for each logo placement

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Start timing
        start_time = time.time()

        # Validate input file
        if not os.path.exists(input_file):
            raise FileNotFoundError(f"Input file not found: {input_file}")

        # Check file size and warn if very large
        file_size_mb = os.path.getsize(input_file) / (1024 * 1024)
        if file_size_mb > 10:
            print(f"Warning: Large file detected ({file_size_mb:.1f}MB). Conversion may take a while...")

        # Generate output filename if not provided
        if not output_file:
            output_file = Path(input_file).with_suffix('.pdf')

        print(f"\n{'='*60}")
        print(f"📄 Converting: {Path(input_file).name}")
        print(f"{'='*60}")
        print(f"[1/5] Reading Markdown file...", end=" ", flush=True)

        # Convert Markdown to HTML
        step_start = time.time()
        html_content, markdown_content, md_instance = convert_markdown_to_html(input_file, enable_toc)
        print(f"✓ ({time.time() - step_start:.2f}s)")

        print(f"[2/5] Processing content...", end=" ", flush=True)
        step_start = time.time()

        # Extract title from document H1 or use filename
        title = extract_title_from_markdown(markdown_content)
        if not title:
            title = Path(input_file).stem.replace('_', ' ').replace('-', ' ').title()

        # Extract front matter (h2, h3, metadata) for title page
        front_matter = extract_front_matter(markdown_content)

        # Get TOC HTML if enabled
        toc_html = None
        if enable_toc and hasattr(md_instance, 'toc'):
            toc_html = md_instance.toc

        print(f"✓ ({time.time() - step_start:.2f}s)")

        # Load custom CSS if provided
        custom_css_content = None
        if custom_css:
            if os.path.exists(custom_css):
                try:
                    with open(custom_css, 'r', encoding='utf-8') as f:
                        custom_css_content = f.read()
                except Exception as e:
                    print(f"Warning: Could not load custom CSS file: {e}")
            else:
                # Assume it's a CSS string
                custom_css_content = custom_css

        print(f"[3/5] Building HTML ({theme} theme)...", end=" ", flush=True)
        step_start = time.time()

        # Create complete HTML document
        complete_html = create_complete_html_document(
            html_content,
            title,
            toc_html=toc_html,
            custom_css=custom_css_content,
            metadata=metadata,
            front_matter=front_matter,
            theme=theme,
            logo_data_uri=logo_data_uri,
            logo_placements=logo_placements or []
        )

        print(f"✓ ({time.time() - step_start:.2f}s)")

        print(f"[4/5] Generating PDF...", end=" ", flush=True)
        step_start = time.time()

        # Generate PDF with font configuration for Unicode support
        font_config = FontConfiguration()
        html_doc = HTML(string=complete_html)
        html_doc.write_pdf(output_file, font_config=font_config)

        print(f"✓ ({time.time() - step_start:.2f}s)")

        # Get file size and total time
        output_size_mb = os.path.getsize(output_file) / (1024 * 1024)
        total_time = time.time() - start_time

        print(f"[5/5] Finalizing...", end=" ", flush=True)
        print(f"✓")
        print(f"{'='*60}")
        print(f"✅ SUCCESS!")
        print(f"{'='*60}")
        print(f"📄 Output: {Path(output_file).name}")
        print(f"📏 Size: {output_size_mb:.2f} MB")
        print(f"⏱️  Time: {total_time:.2f}s")
        if logo_data_uri and logo_placements:
            placements_str = ", ".join([f"{p['position']} ({p['size']})" for p in logo_placements])
            print(f"🏷️  Logo: {placements_str}")
        print(f"🎨 Theme: {theme}")
        print(f"{'='*60}\n")

        return True

    except FileNotFoundError as e:
        print(f"✗ File Error: {e}")
        return False
    except UnicodeDecodeError as e:
        print(f"✗ Encoding Error: Could not read file. Please ensure it's properly encoded.")
        print(f"   Details: {e}")
        return False
    except Exception as e:
        print(f"✗ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main function to handle command line arguments and execute conversion."""
    parser = argparse.ArgumentParser(
        description='Convert Markdown files to styled PDF documents with professional formatting',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s document.md
  %(prog)s input.md -o output.pdf
  %(prog)s document.md --toc --author "John Doe"
  %(prog)s document.md --theme rustic --toc

Logo Branding [NEW v2.1]:
  # Single position (old format - still works)
  %(prog)s doc.md --logo logo.png --logo-position header --logo-size medium

  # Multi-position with different sizes
  %(prog)s doc.md --logo logo.png --logo-placement "title:large" --logo-placement "header:small"

  # Professional report: Large cover logo + small header
  %(prog)s report.md --logo brand.svg --logo-placement "title:large" --logo-placement "header:small" --theme warm

  # Maximum branding: Title + header/footer + watermark
  %(prog)s proposal.md --logo company.png --logo-placement "title:medium" --logo-placement "both:small" --logo-placement "watermark:medium"

Themes:
  default - Clean white paper with neutral colors (original style)
  warm    - Warm neutral tones with vintage typography (new default)
  rustic  - Aged paper with coffee browns and ornamental elements

Features:
  - Three visual themes for different aesthetics
  - Multi-position logo branding with individual sizes [NEW v2.1]
  - Footnote support with [^1] syntax
  - Table of contents generation
  - Unicode support for international characters
  - Custom CSS styling
  - PDF metadata (author, subject, keywords)
  - Professional document formatting
        """
    )

    parser.add_argument(
        'input_file',
        help='Path to the input Markdown file (.md)'
    )

    parser.add_argument(
        '-o', '--output',
        dest='output_file',
        help='Path to the output PDF file (default: same as input with .pdf extension)'
    )

    parser.add_argument(
        '--toc',
        action='store_true',
        help='Generate table of contents'
    )

    parser.add_argument(
        '--css',
        dest='custom_css',
        help='Path to custom CSS file or inline CSS string'
    )

    parser.add_argument(
        '--theme',
        choices=['default', 'warm', 'rustic'],
        default='warm',
        help='Visual theme for PDF output (default: warm)'
    )

    parser.add_argument(
        '--author',
        help='PDF author metadata'
    )

    parser.add_argument(
        '--subject',
        help='PDF subject metadata'
    )

    parser.add_argument(
        '--keywords',
        help='PDF keywords metadata (comma-separated)'
    )

    parser.add_argument(
        '--logo',
        dest='logo_path',
        help='Path to company logo file (PNG, SVG, JPG/JPEG) for branding'
    )

    parser.add_argument(
        '--logo-placement',
        dest='logo_placements',
        action='append',
        help='Logo placement in format "position:size" (e.g., "header:small"). Can be used multiple times for different placements.'
    )

    # Keep old arguments for backward compatibility
    parser.add_argument(
        '--logo-position',
        dest='logo_position',
        choices=['header', 'footer', 'both', 'watermark', 'title', 'all'],
        help='(Deprecated) Use --logo-placement instead. Logo placement (default: header)'
    )

    parser.add_argument(
        '--logo-size',
        dest='logo_size',
        choices=['small', 'medium', 'large'],
        help='(Deprecated) Use --logo-placement instead. Logo size (default: medium)'
    )

    args = parser.parse_args()

    # Build metadata dictionary
    metadata = {}
    if args.author:
        metadata['author'] = args.author
    if args.subject:
        metadata['subject'] = args.subject
    if args.keywords:
        metadata['keywords'] = args.keywords

    # Process logo if provided
    logo_data_uri = process_logo_argument(args.logo_path)

    # Parse logo placements
    logo_placements = []
    if args.logo_placements:
        # New format: --logo-placement "header:small" --logo-placement "footer:medium"
        for placement_str in args.logo_placements:
            try:
                if ':' in placement_str:
                    position, size = placement_str.split(':', 1)
                    logo_placements.append({'position': position.strip(), 'size': size.strip()})
                else:
                    print(f"Warning: Invalid logo placement format: {placement_str}. Use 'position:size'")
            except ValueError:
                print(f"Warning: Invalid logo placement format: {placement_str}. Use 'position:size'")
    elif args.logo_position:
        # Backward compatibility: old --logo-position --logo-size format
        logo_placements.append({
            'position': args.logo_position,
            'size': args.logo_size or 'medium'
        })

    # Convert the files
    success = convert_md_to_pdf(
        args.input_file,
        args.output_file,
        enable_toc=args.toc,
        custom_css=args.custom_css,
        metadata=metadata if metadata else None,
        theme=args.theme,
        logo_data_uri=logo_data_uri,
        logo_placements=logo_placements
    )

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()