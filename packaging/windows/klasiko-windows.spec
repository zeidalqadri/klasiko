# -*- mode: python ; coding: utf-8 -*-
#
# PyInstaller spec file for Klasiko PDF Converter (Windows)
# Creates a standalone Windows executable (.exe)
#
# Build with: pyinstaller klasiko-windows.spec
#

import sys
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# Collect data files for WeasyPrint and its dependencies
weasyprint_datas = collect_data_files('weasyprint')
pyphen_datas = collect_data_files('pyphen')
tinycss2_datas = collect_data_files('tinycss2')
cairocffi_datas = collect_data_files('cairocffi')

# Collect GTK3 and related libraries for Windows
# WeasyPrint on Windows requires Cairo, Pango, GDK-PixBuf
try:
    import cairo
    import cairocffi
    # These will bundle the necessary DLLs
except ImportError:
    print("Warning: Cairo libraries may not be fully available")

# Combine all data files
all_datas = []
all_datas += weasyprint_datas
all_datas += pyphen_datas
all_datas += tinycss2_datas
all_datas += cairocffi_datas

a = Analysis(
    ['../../klasiko.py'],  # Relative path from packaging/windows/
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
        # Windows-specific imports
        'cairocffi.ffi',
        'cffi.backend_ctypes',
        '_cffi_backend',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='klasiko',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,  # Console application for command-line usage
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='klasiko.ico',  # Windows icon file
    version_file=None,  # Could add version info later
)

# Note: Windows doesn't use COLLECT/BUNDLE like macOS
# The exe object above creates a single-file executable with everything bundled
