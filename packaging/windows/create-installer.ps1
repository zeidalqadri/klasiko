# Klasiko Windows Installer Creation Script
# Creates a Windows installer using Inno Setup
#
# Usage: .\packaging\windows\create-installer.ps1
#
# Requirements:
#   - Inno Setup 6.0 or higher installed
#   - klasiko.exe built in dist/ directory

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
Write-Host "║          KLASIKO WINDOWS INSTALLER CREATION                ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

Set-Location $ProjectRoot

# Step 1: Verify klasiko.exe exists
Write-Step 1 6 "Verifying klasiko.exe exists..."

$ExePath = "dist\klasiko.exe"
if (-not (Test-Path $ExePath)) {
    Write-Error-Custom "klasiko.exe not found at $ExePath"
    Write-Host "Please run .\packaging\windows\build-win.ps1 first" -ForegroundColor Red
    exit 1
}

$ExeSize = (Get-Item $ExePath).Length
$ExeSizeMB = [math]::Round($ExeSize / 1MB, 2)
Write-Success "Found klasiko.exe ($ExeSizeMB MB)"
Write-Host ""

# Step 2: Find Inno Setup
Write-Step 2 6 "Locating Inno Setup..."

$IsccPaths = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 5\ISCC.exe"
)

$IsccPath = $null
foreach ($Path in $IsccPaths) {
    if (Test-Path $Path) {
        $IsccPath = $Path
        break
    }
}

if (-not $IsccPath) {
    Write-Error-Custom "Inno Setup not found"
    Write-Host ""
    Write-Host "Please install Inno Setup from:" -ForegroundColor Yellow
    Write-Host "https://jrsoftware.org/isdl.php" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Success "Found Inno Setup: $IsccPath"
Write-Host ""

# Step 3: Copy executable to packaging directory
Write-Step 3 6 "Preparing files..."

$PackagingExePath = "packaging\windows\dist\klasiko.exe"
$PackagingDistDir = "packaging\windows\dist"

if (-not (Test-Path $PackagingDistDir)) {
    New-Item -ItemType Directory -Path $PackagingDistDir | Out-Null
}

Copy-Item $ExePath $PackagingExePath -Force
Write-Success "Copied klasiko.exe to packaging directory"
Write-Host ""

# Step 4: Clean previous installers
Write-Step 4 6 "Cleaning previous installers..."

$InstallerPattern = "dist\Klasiko-*-Windows-Setup.exe"
$OldInstallers = Get-ChildItem $InstallerPattern -ErrorAction SilentlyContinue

if ($OldInstallers) {
    foreach ($Installer in $OldInstallers) {
        Remove-Item $Installer.FullName -Force
        Write-Success "Removed $($Installer.Name)"
    }
} else {
    Write-Info "No previous installers found"
}
Write-Host ""

# Step 5: Build installer with Inno Setup
Write-Step 5 6 "Building installer with Inno Setup..."
Write-Info "This may take a minute..."
Write-Host ""

try {
    $IsccArgs = @(
        "packaging\windows\klasiko-installer.iss"
    )

    $Process = Start-Process -FilePath $IsccPath -ArgumentList $IsccArgs `
        -NoNewWindow -Wait -PassThru

    if ($Process.ExitCode -eq 0) {
        Write-Host ""
        Write-Success "Installer built successfully"
    } else {
        Write-Host ""
        Write-Error-Custom "Inno Setup failed with exit code $($Process.ExitCode)"
        exit 1
    }
} catch {
    Write-Host ""
    Write-Error-Custom "Failed to run Inno Setup: $_"
    exit 1
}

Write-Host ""

# Step 6: Verify installer
Write-Step 6 6 "Verifying installer..."

$InstallerPath = Get-ChildItem "dist\Klasiko-*-Windows-Setup.exe" | Select-Object -First 1

if (-not $InstallerPath) {
    Write-Error-Custom "Installer not found in dist/"
    exit 1
}

$InstallerSize = (Get-Item $InstallerPath.FullName).Length
$InstallerSizeMB = [math]::Round($InstallerSize / 1MB, 2)

Write-Success "Installer created: $($InstallerPath.Name)"
Write-Success "Installer size: $InstallerSizeMB MB"

# Success summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║               INSTALLER CREATED SUCCESSFULLY!              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Installer location: " -NoNewline
Write-Host "$($InstallerPath.FullName)" -ForegroundColor Blue
Write-Host "Installer size:     " -NoNewline
Write-Host "$InstallerSizeMB MB" -ForegroundColor Blue
Write-Host ""
Write-Host "Features included:" -ForegroundColor Cyan
Write-Host "  ✓ Klasiko executable"
Write-Host "  ✓ Optional PATH environment variable integration"
Write-Host "  ✓ Optional .md file association (right-click context menu)"
Write-Host "  ✓ Start Menu shortcuts"
Write-Host "  ✓ Documentation (README, CHANGELOG, THEME-GUIDE)"
Write-Host "  ✓ Uninstaller"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Test the installer on a Windows machine"
Write-Host "  2. Run the installer and verify all features work"
Write-Host "  3. Test PDF conversion with different themes"
Write-Host "  4. Distribute the installer to users"
Write-Host ""
