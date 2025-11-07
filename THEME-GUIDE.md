# Klasiko Theme Guide

## Overview

Klasiko now supports **three visual themes** that transform the aesthetic of your PDF documents while maintaining all functionality (footnotes, TOC, tables, Unicode support).

## Theme Comparison

### 1. Default Theme (`--theme default`)
**Character**: Clean, professional, academic
**Best For**: Technical documentation, research papers, formal reports

**Visual Characteristics:**
- White background (#FFFFFF)
- Neutral gray tones (#333, #666)
- Times New Roman fonts
- Single-line borders
- Minimal decoration (bullet points •)
- Traditional page numbers ("Page 5")
- Clean, sterile aesthetic

**Use Cases:**
- Academic papers
- Technical documentation
- Corporate reports
- When maximum readability is priority

### 2. Warm Theme (`--theme warm`) **[DEFAULT]**
**Character**: Professional with personality, vintage sophistication
**Best For**: Professional documents, presentations, client-facing materials

**Visual Characteristics:**
- Warm off-white background (#FAF8F5)
- Warm brown-gray text (#3A3229)
- Palatino/Garamond serif fonts
- **Double borders** on headings (3px double lines)
- **Small-caps typography** for H1, H2, and table headers
- **Vintage page numbers** ("– 5 –" with em dashes)
- **Elegant flourishes** (❦ ornaments in headers/footers)
- **Alternating table rows** with warm tones
- **Generous spacing** (3cm margins)
- **Letter-spacing** on titles for gravitas

**Improvements Over Default:**
- +40% warmer color temperature
- +25% larger margins for breathing room
- Bold headings instead of normal weight
- Double-line borders add sophistication
- Small-caps add classical elegance
- Decorative page elements add character

**Use Cases:**
- Business proposals
- Product requirements documents
- Client presentations
- Portfolio documents
- Professional reports with personality

### 3. Rustic Theme (`--theme rustic`)
**Character**: Maximum vintage, artisanal, coffee-shop aesthetic
**Best For**: Creative documents, brand materials, storytelling

**Visual Characteristics:**
- Aged paper background (#F4ECD8 - cream/beige)
- Coffee brown text (#2B1F17)
- Palatino/Garamond fonts
- **Ornamental dividers** (✦ diamonds, ❧ fleurons)
- **Decorative title page** with triple diamonds
- **Gradient horizontal rules** with centered ornaments
- **Decorative quote marks** in blockquotes
- **Coffee brown color palette** (#8B7355, #A0826D)
- **Vintage ledger-style tables** with warm backgrounds
- **Small-caps headings** throughout
- Maximum ornamental character

**Improvements Over Warm:**
- Aged paper instead of white/off-white
- Full coffee shop color palette
- Ornamental dividers between sections
- Decorative title page with flourishes
- Maximum vintage aesthetic

**Use Cases:**
- Creative briefs
- Brand story documents
- Coffee shop/restaurant materials
- Artisanal product documentation
- Documents where personality > formality
- Vietnamese-heritage brand materials (like Kopi Saigon)

## Theme Selection Guide

### Choose DEFAULT if:
- ✓ Maximum formality required
- ✓ Academic or scientific paper
- ✓ Corporate environment with strict guidelines
- ✓ Minimal file size is priority
- ✓ Black & white printing required

### Choose WARM if: **[RECOMMENDED]**
- ✓ Professional but approachable tone desired
- ✓ Client-facing documents
- ✓ Modern business communication
- ✓ Balance between formal and friendly
- ✓ Want subtle personality without going full vintage
- ✓ Product requirements, proposals, reports

### Choose RUSTIC if:
- ✓ Creative or artisanal brand
- ✓ Storytelling or narrative documents
- ✓ Coffee shop, restaurant, boutique materials
- ✓ Maximum visual character desired
- ✓ Brand guidelines allow decorative elements
- ✓ Vietnamese-heritage or cultural documents

## Usage Examples

### Basic Usage (Warm Theme - Default)
```bash
python klasiko.py document.md --toc
```

### Explicit Warm Theme
```bash
python klasiko.py document.md --theme warm --toc
```

### Clean Professional (Default Theme)
```bash
python klasiko.py research-paper.md --theme default --toc
```

### Maximum Vintage (Rustic Theme)
```bash
python klasiko.py brand-story.md --theme rustic --toc
```

### With All Options
```bash
python klasiko.py document.md \
  --theme rustic \
  --toc \
  --author "Product Team" \
  --subject "Brand Materials" \
  -o output.pdf
```

## Technical Details

### File Size Comparison
Testing with kopi-saigon-prd-comprehensive.md (1,873 lines):
- **Default**: 726KB (baseline)
- **Warm**: 861KB (+19%) - slightly larger due to Unicode ornaments
- **Rustic**: 851KB (+17%) - similar to warm

### Font Stacks

**Default Theme:**
```css
body: 'Times New Roman', 'DejaVu Serif', 'Noto Serif', Times, serif
headings: Georgia, 'Times New Roman', Times, serif
```

**Warm & Rustic Themes:**
```css
body: 'Palatino Linotype', 'Book Antiqua', Palatino, 'Garamond', Georgia, serif
headings: 'Garamond', 'Palatino Linotype', 'Book Antiqua', Georgia, serif
```

### Color Palettes

**Default Theme:**
- Background: #FFFFFF (pure white)
- Text: #333 (dark gray)
- Headings: #222 (darker gray)
- Borders: #ccc, #ddd, #eee (light grays)

**Warm Theme:**
- Background: #FAF8F5 (warm off-white)
- Text: #3A3229 (warm brown-gray)
- Headings: #2D2520 (deep warm brown)
- Accents: #9B8579 (warm taupe)
- Borders: #D4C4B5 (warm beige)

**Rustic Theme:**
- Background: #F4ECD8 (aged paper cream)
- Text: #2B1F17 (brown-black ink)
- Headings: #3D2B1F (dark brown)
- Accents: #8B7355, #A0826D (coffee browns)
- Borders: #C9B899 (aged gold/tan)

### Typography Features by Theme

| Feature | Default | Warm | Rustic |
|---------|---------|------|--------|
| Heading Weight | Normal | **Bold** | **Bold** |
| Small-Caps | No | H1, H2 | H1, H2, H3 |
| Letter-Spacing | No | Yes (titles) | Yes (titles) |
| Border Style | Single (1px) | **Double (3px)** | **Double (3-4px)** |
| Page Numbers | "Page 5" | "– 5 –" | "– 5 –" |
| Decorative Elements | Bullets (•) | Fleurons (❦) | Multiple (❧, ✦, ⁂) |
| Font Size | 12pt | 11.5pt | 11.5pt |
| Line Height | 1.6 | 1.7 | 1.7 |
| Margins | 2.5cm/2cm | 3cm/2.5cm | 3cm/2.5cm |

## Theme Customization

### Combining with Custom CSS

You can override theme styles with custom CSS:

```bash
python klasiko.py document.md --theme warm --css custom.css
```

Custom CSS takes precedence and is appended after theme CSS.

### Creating Your Own Theme

To add a new theme:

1. Create a new function in `klasiko.py`:
```python
def get_mytheme_css():
    return """
        /* Your CSS here */
    """
```

2. Add to theme selector:
```python
def get_theme_css(theme='warm'):
    themes = {
        'default': get_default_theme_css,
        'warm': get_warm_theme_css,
        'rustic': get_rustic_theme_css,
        'mytheme': get_mytheme_css  # Add your theme
    }
```

3. Update command-line choices:
```python
parser.add_argument(
    '--theme',
    choices=['default', 'warm', 'rustic', 'mytheme'],
    ...
)
```

## Design Philosophy

### Default Theme
**Philosophy**: "Invisible design - don't distract from content"
- Prioritizes readability
- Zero personality by design
- Academic neutrality
- Maximum compatibility

### Warm Theme
**Philosophy**: "Professional warmth - personality without sacrifice"
- Balances professionalism with approachability
- Adds character through typography, not color
- Sophisticated without being ornate
- Modern vintage aesthetic

### Rustic Theme
**Philosophy**: "Maximum character - embrace the aesthetic"
- Full vintage/artisanal expression
- Ornamental and decorative
- Coffee shop / artisan brand aesthetic
- Cultural and narrative emphasis

## Feedback & Iteration

The warm theme is now the default because it provides:
1. **Professional quality** matching default theme
2. **Visual warmth** and personality
3. **Vintage sophistication** without going overboard
4. **Better hierarchy** through bold headings and small-caps
5. **Elegant touches** (double borders, decorative page numbers)

For maximum formality, use `--theme default`.
For maximum character, use `--theme rustic`.
For the best of both worlds, use `--theme warm` (or omit the flag).

## Unicode Ornaments Used

**Warm Theme:**
- ❦ (U+2766) - Fleuron ornament

**Rustic Theme:**
- ❧ (U+2767) - Fleuron (pointing leaf)
- ✦ (U+2726) - Black four pointed star
- \u201C - Left double quotation mark (in blockquotes)

These ornaments are universally supported and render consistently across platforms.
