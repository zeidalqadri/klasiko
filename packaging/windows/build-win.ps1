# Klasiko Windows Build Script
# Builds a standalone Windows executable (.exe)
#
# Usage: .\packaging\windows\build-win.ps1
#
# Requirements:
#   - Python 3.8 or higher
#   - Virtual environment with dependencies installed
#   - PyInstaller

# Set error handling
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-Step {
    param($StepNum, $Total, $Message)
    Write-Host "[$StepNum/$Total] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param($Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param($Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param($Message)
    Write-Host "  → $Message" -ForegroundColor Blue
}

# Print header
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║               KLASIKO WINDOWS BUILD                        ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

Set-Location $ProjectRoot

# Step 1: Clean previous builds
Write-Step 1 5 "Cleaning previous builds..."
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
    Write-Success "Removed build/"
}
if (Test-Path "dist") {
    Remove-Item -Recurse -Force "dist"
    Write-Success "Removed dist/"
}
if (Test-Path "klasiko.spec") {
    Remove-Item -Force "klasiko.spec"
    Write-Success "Removed old klasiko.spec"
}
Write-Host ""

# Step 2: Activate virtual environment
Write-Step 2 5 "Activating virtual environment..."
if (-not (Test-Path "venv")) {
    Write-Error-Custom "Virtual environment not found at venv/"
    Write-Host "Please run: python -m venv venv" -ForegroundColor Red
    Write-Host "Then: .\venv\Scripts\pip install -r requirements.txt" -ForegroundColor Red
    exit 1
}

# Activate venv (Windows)
$VenvPython = ".\venv\Scripts\python.exe"
$VenvPip = ".\venv\Scripts\pip.exe"

if (-not (Test-Path $VenvPython)) {
    Write-Error-Custom "Python not found in virtual environment"
    exit 1
}

Write-Success "Virtual environment found"
Write-Host ""

# Step 3: Verify PyInstaller is installed
Write-Step 3 5 "Verifying PyInstaller installation..."
$PyInstallerPath = ".\venv\Scripts\pyinstaller.exe"

if (-not (Test-Path $PyInstallerPath)) {
    Write-Host "PyInstaller not found. Installing..." -ForegroundColor Yellow
    & $VenvPip install pyinstaller
    if (-not (Test-Path $PyInstallerPath)) {
        Write-Error-Custom "Failed to install PyInstaller"
        exit 1
    }
}

$PyInstallerVersion = & $PyInstallerPath --version 2>&1
Write-Success "PyInstaller $PyInstallerVersion"
Write-Host ""

# Step 4: Build with PyInstaller
Write-Step 4 5 "Building klasiko.exe with PyInstaller..."
Write-Info "This may take several minutes..."
Write-Host ""

# Change to packaging/windows directory to use relative paths in spec file
Set-Location "packaging\windows"

try {
    & ..\..\venv\Scripts\pyinstaller.exe klasiko-windows.spec 2>&1 | Out-Host
    Write-Host ""
    Write-Success "Build completed successfully"
} catch {
    Write-Host ""
    Write-Error-Custom "Build failed: $_"
    Set-Location $ProjectRoot
    exit 1
}

# Return to project root
Set-Location $ProjectRoot

Write-Host ""

# Step 5: Verify the build
Write-Step 5 5 "Verifying build..."

$ExePath = "packaging\windows\dist\klasiko.exe"
if (-not (Test-Path $ExePath)) {
    Write-Error-Custom "klasiko.exe not found at $ExePath"
    exit 1
}

Write-Success "Executable found at $ExePath"

# Get executable size
$ExeSize = (Get-Item $ExePath).Length
$ExeSizeMB = [math]::Round($ExeSize / 1MB, 2)
Write-Success "Executable size: $ExeSizeMB MB"

# Test basic functionality
Write-Host ""
Write-Host "Testing basic functionality..." -ForegroundColor Yellow
try {
    $TestOutput = & $ExePath --help 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Application executable works"
    } else {
        Write-Host "  ! Warning: Application test returned non-zero exit code" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ! Warning: Application test failed (may need GTK3 runtime)" -ForegroundColor Yellow
}

# Copy to dist/ directory in project root for consistency with macOS
if (-not (Test-Path "dist")) {
    New-Item -ItemType Directory -Path "dist" | Out-Null
}
Copy-Item $ExePath "dist\klasiko.exe" -Force
Write-Success "Copied to dist\klasiko.exe"

# Success summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    BUILD SUCCESSFUL!                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Executable location: " -NoNewline
Write-Host "dist\klasiko.exe" -ForegroundColor Blue
Write-Host "Executable size:     " -NoNewline
Write-Host "$ExeSizeMB MB" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Test the executable: .\dist\klasiko.exe --help"
Write-Host "  2. Create installer: .\packaging\windows\create-installer.ps1"
Write-Host "  3. Or use the GUI: python klasiko-gui.py"
Write-Host ""
