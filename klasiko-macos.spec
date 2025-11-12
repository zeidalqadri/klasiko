# -*- mode: python ; coding: utf-8 -*-
#
# PyInstaller spec file for Klasiko PDF Converter (macOS)
# Creates a universal binary (.app) for both Intel and Apple Silicon Macs
#
# Build with: pyinstaller klasiko-macos.spec

import sys
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# Collect data files for WeasyPrint and its dependencies
weasyprint_datas = collect_data_files('weasyprint')
pyphen_datas = collect_data_files('pyphen')
tinycss2_datas = collect_data_files('tinycss2')
cairocffi_datas = collect_data_files('cairocffi')

# Combine all data files
all_datas = []
all_datas += weasyprint_datas
all_datas += pyphen_datas
all_datas += tinycss2_datas
all_datas += cairocffi_datas

# Add our shell script libraries
all_datas += [
    ('lib/terminal-ui.sh', 'lib'),
    ('lib/dialogs.sh', 'lib'),
]

a = Analysis(
    ['klasiko.py'],
    pathex=[],
    binaries=[],
    datas=all_datas,
    hiddenimports=[
        'weasyprint',
        'pyphen',
        'tinycss2',
        'cairocffi',
        'cffi',
        'markdown',
        'pygments',
        'weasyprint.css',
        'weasyprint.css.counters',
        'weasyprint.css.targets',
        'weasyprint.text',
        'weasyprint.layout',
        'html5lib',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
    target_arch=None,  # Use native architecture (arm64 on Apple Silicon)
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='klasiko',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,  # Keep console for terminal-based interactive mode
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,  # Use native architecture
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='klasiko',
)

app = BUNDLE(
    coll,
    name='Klasiko.app',
    icon=None,  # TODO: Add custom icon if desired
    bundle_identifier='com.klasiko.pdfconverter',
    version='2.1.0',
    info_plist={
        'CFBundleName': 'Klasiko',
        'CFBundleDisplayName': 'Klasiko PDF Converter',
        'CFBundleShortVersionString': '2.1.0',
        'CFBundleVersion': '2.1.0',
        'CFBundlePackageType': 'APPL',
        'CFBundleExecutable': 'klasiko',
        'LSMinimumSystemVersion': '10.13.0',
        'NSHighResolutionCapable': True,
        'NSRequiresAquaSystemAppearance': False,
    },
)
