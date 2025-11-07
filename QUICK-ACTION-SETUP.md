# Klasiko Quick Action Setup Guide

## Creating the Right-Click "Convert to PDF" Action

Follow these steps to add an **interactive "Convert to PDF with Klasiko"** workflow to your Finder's right-click menu with theme selection and logo branding options.

### Step 1: Open Automator

1. Open **Automator.app** (press ⌘+Space, type "Automator", press Enter)
2. Click **"New Document"** if prompted
3. Select **"Quick Action"** (or "Service" in older macOS versions)
4. Click **"Choose"**

### Step 2: Configure Quick Action Settings

In the top panel of the workflow area:

1. Set **"Workflow receives current"** to: **"files or folders"**
2. Set **"in"** to: **"Finder"**
3. Leave image/color as default (optional: can customize later)

### Step 3: Add the Shell Script Action

1. In the left sidebar, search for **"Run Shell Script"**
2. Drag **"Run Shell Script"** to the workflow area on the right
3. In the "Run Shell Script" action:
   - Set **Shell** to: **/bin/bash**
   - Set **"Pass input"** to: **"as arguments"**

### Step 4: Paste the Shell Script

Delete the default text in the script box and paste this:

```bash
#!/bin/bash

# Klasiko Quick Action - Convert Markdown to PDF with Theme Selection
# Shows dialog to choose theme, then converts selected .md files

SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"
VENV_PATH="$SCRIPT_DIR/venv"
PYTHON_SCRIPT="$SCRIPT_DIR/klasiko.py"

# Ask user to select theme
THEME=$(osascript -e '
tell application "System Events"
    activate
    set themeChoice to button returned of (display dialog "Choose PDF theme:" buttons {"Default", "Warm", "Rustic"} default button "Warm" with title "Klasiko PDF Converter")
    return themeChoice
end tell' | tr '[:upper:]' '[:lower:]')

# Check if user cancelled
if [ -z "$THEME" ]; then
    osascript -e 'display notification "Conversion cancelled" with title "Klasiko PDF Converter"'
    exit 0
fi

# Process each selected file
for file in "$@"
do
    # Check if file is a Markdown file
    if [[ "$file" == *.md ]]; then
        # Get the output PDF path (same directory, same name, .pdf extension)
        output_file="${file%.md}.pdf"

        # Activate venv and run the script
        cd "$SCRIPT_DIR"
        source "$VENV_PATH/bin/activate"

        # Run conversion (no --toc by default as requested)
        python "$PYTHON_SCRIPT" "$file" -o "$output_file" --theme "$THEME"

        # Check if conversion was successful
        if [ $? -eq 0 ] && [ -f "$output_file" ]; then
            osascript -e "display notification \"Converted with $THEME theme: $(basename "$file")\" with title \"Klasiko PDF Converter\" sound name \"Glass\""
        else
            osascript -e "display notification \"Failed to convert: $(basename "$file")\" with title \"Klasiko PDF Converter\" sound name \"Basso\""
        fi

        deactivate
    else
        osascript -e "display notification \"Not a Markdown file: $(basename "$file")\" with title \"Klasiko PDF Converter\" sound name \"Basso\""
    fi
done
```

### Step 5: Save the Quick Action

1. Click **File → Save** (or press ⌘S)
2. Name it: **"Convert to PDF with Klasiko"**
3. The save location will automatically be: `~/Library/Services/`
4. Click **Save**

### Step 6: Enable the Quick Action (if needed)

The Quick Action should be automatically enabled, but if it doesn't appear:

1. Open **System Settings** (or System Preferences)
2. Go to **Privacy & Security → Extensions → Finder** (or **Extensions → Finder**)
3. Find **"Convert to PDF with Klasiko"** and ensure it's **checked**

Alternative location:
- **System Settings → Keyboard → Keyboard Shortcuts → Services**
- Scroll to **"Files and Folders"** section
- Find **"Convert to PDF with Klasiko"** and ensure it's **checked**

### Step 7: Test It Out!

1. Open **Finder**
2. Navigate to any folder with a `.md` file
3. **Right-click** (or Control-click) on the `.md` file
4. Look for **Quick Actions → "Convert to PDF with Klasiko"**
5. Click it
6. A dialog will appear asking you to choose a theme: **Default**, **Warm**, or **Rustic**
7. Select your preferred theme
8. Wait a moment - you'll see a notification when it's done
9. The PDF will appear in the same directory as the `.md` file

## How It Works

- **Theme Selection**: Dialog appears first with 3 buttons (Default/Warm/Rustic)
- **No TOC by default**: Converts quickly without table of contents (as requested)
- **Multiple files**: You can select multiple `.md` files and convert them all at once
- **Success notification**: Shows notification with theme name when done
- **Error handling**: Shows error notification if conversion fails
- **Smart filtering**: Only processes `.md` files, ignores other file types

## Troubleshooting

### Quick Action doesn't appear in right-click menu

**Solution 1**: Restart Finder
- Hold **Option** key
- Right-click on **Finder** icon in Dock
- Click **Relaunch**

**Solution 2**: Check Extensions settings
- System Settings → Extensions → Finder
- Ensure "Convert to PDF with Klasiko" is checked

**Solution 3**: Log out and log back in

### Dialog doesn't appear or script fails silently

**Check permissions**:
- System Settings → Privacy & Security → Automation
- Ensure Automator has permissions

**Check logs**:
- Open **Console.app**
- Search for "Automator" or "klasiko"
- Look for error messages

### PDF not created or error notification appears

**Check script paths**:
- Ensure `/Users/zeidalqadri/Desktop/klasiko/` contains:
  - `klasiko.py`
  - `venv/` directory with activated virtual environment

**Test manually**:
```bash
cd /Users/zeidalqadri/Desktop/klasiko
source venv/bin/activate
python klasiko.py test.md
```

### Want to add TOC automatically?

Edit the Quick Action in Automator and change this line:
```bash
python "$PYTHON_SCRIPT" "$file" -o "$output_file" --theme "$THEME"
```

To:
```bash
python "$PYTHON_SCRIPT" "$file" -o "$output_file" --theme "$THEME" --toc
```

## Customization Options

### Change Default Theme in Dialog

In the script, change `default button "Warm"` to:
- `default button "Default"` - for clean academic style
- `default button "Rustic"` - for maximum vintage

### Skip Theme Dialog (Always Use One Theme)

Replace the entire script with this simpler version:

```bash
#!/bin/bash
SCRIPT_DIR="/Users/zeidalqadri/Desktop/klasiko"

for file in "$@"
do
    if [[ "$file" == *.md ]]; then
        cd "$SCRIPT_DIR"
        source venv/bin/activate
        python klasiko.py "$file" --theme warm
        deactivate

        if [ $? -eq 0 ]; then
            osascript -e "display notification \"Converted: $(basename "$file")\" with title \"Klasiko PDF Converter\""
        fi
    fi
done
```

Change `--theme warm` to `default` or `rustic` as desired.

## Uninstalling

To remove the Quick Action:

1. Open Finder
2. Press ⌘+Shift+G (Go to Folder)
3. Type: `~/Library/Services/`
4. Delete **"Convert to PDF with Klasiko.workflow"**
5. Restart Finder

## Command-Line Usage

You can also use klasiko from the terminal now:

```bash
# Basic conversion (warm theme)
klasiko document.md

# With specific theme
klasiko document.md --theme rustic

# With table of contents
klasiko document.md --toc

# With all options
klasiko document.md --theme rustic --toc --author "Your Name" -o output.pdf
```

## Need Help?

If you encounter issues:
1. Check this guide's Troubleshooting section
2. Test the command-line version: `klasiko --help`
3. Check Console.app for error messages
4. Verify paths in the script match your setup

---

**Quick Action Created**: $(date)
**Klasiko Version**: 2.0 with Multi-Theme System
