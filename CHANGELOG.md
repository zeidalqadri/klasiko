# Changelog

## Version 1.1 - Front Matter Enhancement (November 6, 2025)

### Major Changes

#### Removed Generic "Generated from Markdown" Text
- **Before**: Title page displayed generic text "Generated from Markdown"
- **After**: Title page now displays actual document headers and metadata

#### Smart Front Matter Extraction
Added intelligent extraction of document structure for the title page:

1. **H1 (Title)**: Primary document title
2. **H2 (Subtitle)**: Document subtitle (only if immediately after H1)
3. **H3 (Sub-subtitle)**: Additional subtitle (only if immediately after H2)
4. **Metadata**: Bold key-value pairs like `**Date:** value`

### Example Output

For a document structured like:
```markdown
# PRODUCT REQUIREMENTS DOCUMENT
## Hyper-Customizable Mobile App Development Project
### Kopi Saigon Coffee Franchise (Malaysia Operations)

**Document Version:** 1.0
**Date:** November 6, 2025
**Project Duration:** 28 weeks (7 months) to MVP Launch
**Prepared for:** Kopi Saigon Malaysia

---

## EXECUTIVE SUMMARY
Content starts here...
```

The title page will display:
```
PRODUCT REQUIREMENTS DOCUMENT
Hyper-Customizable Mobile App Development Project
Kopi Saigon Coffee Franchise (Malaysia Operations)

Document Version: 1.0
Date: November 6, 2025
Project Duration: 28 weeks (7 months) to MVP Launch
Prepared for: Kopi Saigon Malaysia
```

### Technical Implementation

#### New Functions
- `extract_front_matter(markdown_content)`: Extracts H1, H2, H3, and metadata
- Smart detection: Only treats H2/H3 as subtitles if they appear before any content
- Stops at horizontal rules (`---`) or when content paragraphs start

#### Updated Functions
- `create_complete_html_document()`: Now accepts `front_matter` parameter
- `convert_md_to_pdf()`: Extracts and passes front matter to HTML generation

#### Enhanced CSS
Added styling for title page elements:
- `.title-page h2`: Subtitle styling (16pt, normal weight)
- `.title-page h3`: Sub-subtitle styling (14pt, italic)
- `.meta-info`: Metadata section with proper spacing
- `.meta-key`: Bold keys for metadata items

### Console Output Enhancements

The script now provides detailed feedback:
```
Extracted title from document: PRODUCT REQUIREMENTS DOCUMENT
Extracted subtitle: Hyper-Customizable Mobile App Development Project
Extracted sub-subtitle: Kopi Saigon Coffee Franchise (Malaysia Operations)
Extracted 4 metadata items
```

### Edge Cases Handled

1. **Document with only title**: Works correctly, no subtitle shown
2. **Document with content before H2**: H2 is NOT treated as subtitle
3. **Document with horizontal rule**: Stops extraction at `---`
4. **Missing metadata**: Gracefully handles documents without metadata

### Test Results

✅ **kopi-saigon-prd-comprehensive.md**: Successfully extracted all front matter
- Title: PRODUCT REQUIREMENTS DOCUMENT
- Subtitle: Hyper-Customizable Mobile App Development Project
- Sub-subtitle: Kopi Saigon Coffee Franchise (Malaysia Operations)
- 4 metadata items
- Output: 0.7MB PDF, 60-80 pages

✅ **Simple documents**: Correctly don't extract content headings as subtitles
✅ **Documents with full structure**: All H1, H2, H3, and metadata displayed
✅ **Documents without metadata**: Works without errors

### Backward Compatibility

- ✅ Existing command-line options unchanged
- ✅ Documents without H2/H3 still work (shows only title)
- ✅ All previous features maintained (footnotes, TOC, Unicode, etc.)

### Files Modified

- `klasiko.py`: Added front matter extraction and title page generation
  - Lines 59-144: New `extract_front_matter()` function
  - Lines 464-496: Enhanced title page CSS
  - Lines 523-555: Dynamic title page HTML generation
  - Lines 624-631: Front matter extraction and logging

### Usage

No changes to command-line usage. The enhancement automatically applies:

```bash
# Automatic front matter extraction
python klasiko.py document.md --toc

# Works with all existing options
python klasiko.py document.md \
  --toc \
  --author "Author Name" \
  --subject "Document Subject" \
  -o output.pdf
```

### Benefits

1. **Professional appearance**: Title pages match document structure
2. **No manual intervention**: Automatic extraction from document
3. **Flexible**: Works with various document structures
4. **Intelligent**: Only extracts front matter, not content headings
5. **Informative**: Console shows what was extracted
