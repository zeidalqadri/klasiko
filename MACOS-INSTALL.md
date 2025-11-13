# macOS Installation Guide

## ⚠️ Important: Downloaded Klasiko from GitHub?

If you downloaded Klasiko from GitHub Releases, you may see this error when trying to open the app:

> **"Klasiko.app is damaged and can't be opened. You should move it to the Trash."**

**Don't panic!** The app is NOT damaged. This is macOS Gatekeeper's security warning for apps that aren't signed with an Apple Developer certificate.

### Why This Happens

- Klasiko is **free and open-source**
- Apple charges **$99/year** for a Developer ID certificate to sign apps
- To keep Klasiko free, we use "ad-hoc" signing instead
- macOS marks downloaded unsigned apps as "quarantined"
- When you try to open it, Gatekeeper blocks it with the "damaged" error

**This is normal and safe** - many popular open-source Mac apps work this way.

---

## Installation Methods

Choose the method that works best for you:

### Method 1: Standard Installation (Recommended) ⭐

**Simple 4-step process:**

1. **Download** `Klasiko-X.X.X-macOS.dmg` from [GitHub Releases](https://github.com/zeidalqadri/klasiko/releases)

2. **Install** - Open the DMG and drag Klasiko.app to Applications folder

3. **Remove quarantine** - Open Terminal and run:
   ```bash
   xattr -cr /Applications/Klasiko.app
   ```

   This removes the `com.apple.quarantine` flag that causes the "damaged app" error.

4. **Open** Klasiko from Applications folder

**Optional**: Create command-line shortcut to use `klasiko` from Terminal:
```bash
sudo ln -sf /Applications/Klasiko.app/Contents/MacOS/klasiko /usr/local/bin/klasiko
```

---

### Method 2: Install from Source

If you prefer to run from Python source:

```bash
# Clone the repository
git clone https://github.com/zeidalqadri/klasiko.git
cd klasiko

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Use Klasiko
python klasiko.py document.md --theme warm --toc
```

**Advantages:**
- No quarantine issues
- Always latest code
- Can modify if needed

**Disadvantages:**
- Requires Python installation
- Must activate venv each time

---

## Troubleshooting

### "App is damaged" error

**Solution**: Remove quarantine attribute

```bash
xattr -cr /Applications/Klasiko.app
```

### "Can't be opened because it is from an unidentified developer"

**macOS Monterey and earlier:**
1. Go to **System Preferences** → **Security & Privacy**
2. Click the **General** tab
3. Click **"Open Anyway"** next to the Klasiko warning
4. Confirm by clicking **Open**

**macOS Ventura and later:**
1. Go to **System Settings** → **Privacy & Security**
2. Scroll down to **Security** section
3. Click **"Open Anyway"** next to the Klasiko warning
4. Confirm by clicking **Open**

**Alternative (any macOS version):**
1. Right-click (or Control-click) on Klasiko.app
2. Select **Open** from the context menu
3. Click **Open** in the dialog

**Best solution**: Use the `xattr -cr` command - it permanently fixes the issue.

### "Operation not permitted" when running xattr command

**Cause**: Terminal doesn't have Full Disk Access

**Solution**:
1. Go to **System Settings** → **Privacy & Security**
2. Click **Full Disk Access**
3. Click the **+** button
4. Add **Terminal** (or your terminal app)
5. Restart Terminal and try again

**Alternative**: Run the automated installer script which handles this better.

### "klasiko: command not found"

**Cause**: Symlink not created or `/usr/local/bin` not in PATH

**Solution 1** - Create symlink:
```bash
sudo ln -sf /Applications/Klasiko.app/Contents/MacOS/klasiko /usr/local/bin/klasiko
```

**Solution 2** - Add to PATH temporarily:
```bash
export PATH="/Applications/Klasiko.app/Contents/MacOS:$PATH"
```

**Solution 3** - Use full path:
```bash
/Applications/Klasiko.app/Contents/MacOS/klasiko document.md
```

### Still having issues?

1. **Check if app is actually in Applications**:
   ```bash
   ls -la /Applications/Klasiko.app
   ```

2. **Verify quarantine was removed**:
   ```bash
   xattr -l /Applications/Klasiko.app
   ```
   Should show **no quarantine** attribute

3. **Test the executable directly**:
   ```bash
   /Applications/Klasiko.app/Contents/MacOS/klasiko --help
   ```

4. **Check permissions**:
   ```bash
   ls -l /Applications/Klasiko.app/Contents/MacOS/klasiko
   ```
   Should show executable permission (x)

---

## macOS Version-Specific Notes

### macOS Sequoia (15.0+) - 2024

Apple removed the right-click "Open" workaround in Sequoia. **You must use the `xattr -cr` command** or the automated installer script.

### macOS Sonoma (14.0) - 2023

Works with both right-click "Open" and `xattr -cr` command. The automated script is still recommended.

### macOS Ventura (13.0) - 2022

Works well with all methods. Settings moved from System Preferences to System Settings.

### macOS Monterey (12.0) - 2021 and earlier

Classic right-click "Open" workaround still works, but `xattr -cr` is more permanent.

---

## Why Isn't Klasiko Signed?

### The Cost of Code Signing

- **Apple Developer Program**: $99/year
- **Certificate renewal**: Every year, forever
- **Notarization**: Additional complexity and time

### Our Choice

To keep Klasiko **100% free and open-source**, we chose not to pay for code signing. This means:

✅ **No cost to users**
✅ **No subscription fees**
✅ **No tracking or telemetry**
✅ **Fully open source**
✅ **You can verify the code yourself**

❌ Requires one Terminal command to install
❌ Less "polished" installation experience

### Is It Safe?

**Yes!** Here's why you can trust Klasiko:

1. **Open Source**: All code is on GitHub - you can read it yourself
2. **No Network Access**: Klasiko doesn't connect to the internet
3. **Local Processing**: All PDF conversion happens on your Mac
4. **No Data Collection**: Zero telemetry, analytics, or tracking
5. **Community Reviewed**: Open for security audits

The `xattr -cr` command simply tells macOS: "I trust this app, stop quarantining it."

---

## Comparison: Installation Methods

| Method | Ease | CLI Access | Auto-Updates |
|--------|------|------------|--------------|
| **DMG + xattr** | ⭐⭐⭐⭐ Simple (4 steps) | Optional | Manual |
| **Python Source** | ⭐⭐ Requires Python | ✅ Yes | `git pull` |

---

## After Installation

### Using Klasiko

**GUI Mode** (if you have Python source):
```bash
python3 klasiko-gui.py
```

**Command Line**:
```bash
# Basic conversion
klasiko document.md

# With theme and table of contents
klasiko report.md --theme warm --toc

# Multi-position logo branding
klasiko doc.md --logo brand.png \
  --logo-placement "title:large" \
  --logo-placement "header:small"

# Full features
klasiko proposal.md \
  --theme rustic \
  --toc \
  --logo company.svg \
  --logo-placement "title:medium" \
  --logo-placement "both:small" \
  --author "Your Name" \
  --subject "Document Subject"
```

### Get Help

```bash
klasiko --help
```

### Documentation

- **Main README**: [README.md](README.md)
- **Theme Guide**: [THEME-GUIDE.md](THEME-GUIDE.md)
- **Windows Installation**: [WINDOWS-BUILD.md](WINDOWS-BUILD.md)
- **GitHub Issues**: https://github.com/zeidalqadri/klasiko/issues

---

## Future: Proper Code Signing?

If Klasiko becomes popular or commercially viable, we may:

1. Get an Apple Developer account
2. Properly sign and notarize the app
3. Eliminate the installation complexity

But for now, keeping it free is our priority. The one-command installation script makes this pretty painless!

---

## Questions?

**"Can I distribute Klasiko to my team?"**

Yes! Share both the DMG and the `install-klasiko-macos.sh` script. Each person just runs the script.

**"Will Apple ever trust unsigned apps?"**

No - Apple's security model requires paid Developer IDs for automatic trust. This is unlikely to change.

**"Can I build it myself to avoid this?"**

Yes! Follow the build instructions in the main README. Apps you build yourself don't get quarantined.

**"Does this work on M1/M2/M3 Macs?"**

Yes! The app is built natively for Apple Silicon. The quarantine removal works the same way.

**"What about Rosetta on Intel Macs?"**

Klasiko is a universal binary that works natively on both Intel and Apple Silicon. No Rosetta needed.

---

**Thank you for using Klasiko!** 🎨

If this installation guide helped you, consider ⭐ starring the repo on GitHub!
