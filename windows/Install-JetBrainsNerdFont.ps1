#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Downloads and installs JetBrains Mono Nerd Font on Windows 11
.DESCRIPTION
    This script downloads the latest JetBrains Mono Nerd Font from the official GitHub repository
    and installs all font files system-wide on Windows 11.
.NOTES
    Author: DevOps Script
    Requires: Administrator privileges
    Version: 1.0
#>

[CmdletBinding()]
param(
    [string]$FontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip",
    [string]$TempPath = "$env:TEMP\JetBrainsNerdFont"
)

# Script variables
$ErrorActionPreference = "Stop"
$ZipFile = Join-Path $TempPath "JetBrainsMono.zip"
$ExtractPath = Join-Path $TempPath "extracted"
$FontsFolder = [System.Environment]::GetFolderPath('Fonts')
$FontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to clean up temporary files
function Remove-TempFiles {
    if (Test-Path $TempPath) {
        Write-ColorOutput "Cleaning up temporary files..." "Yellow"
        Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
    Write-ColorOutput "`n=== JetBrains Mono Nerd Font Installer ===" "Cyan"
    Write-ColorOutput "Starting installation process...`n" "Cyan"

    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator. Please restart PowerShell with elevated privileges."
    }

    # Create temporary directory
    Write-ColorOutput "Creating temporary directory..." "Green"
    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempPath -Force | Out-Null
    New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null

    # Download font package
    Write-ColorOutput "Downloading JetBrains Mono Nerd Font from GitHub..." "Green"
    Write-ColorOutput "URL: $FontUrl" "Gray"
    
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $FontUrl -OutFile $ZipFile -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    $fileSize = (Get-Item $ZipFile).Length / 1MB
    Write-ColorOutput "Downloaded successfully! Size: $([math]::Round($fileSize, 2)) MB" "Green"

    # Extract zip file
    Write-ColorOutput "`nExtracting font files..." "Green"
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

    # Get all font files (TTF and OTF)
    $fontFiles = Get-ChildItem -Path $ExtractPath -Include "*.ttf", "*.otf" -Recurse | 
                 Where-Object { $_.Name -notlike "*Windows Compatible*" }

    if ($fontFiles.Count -eq 0) {
        throw "No font files found in the downloaded package."
    }

    Write-ColorOutput "Found $($fontFiles.Count) font file(s) to install" "Green"

    # Install fonts
    Write-ColorOutput "`nInstalling fonts..." "Green"
    $installedCount = 0
    $skippedCount = 0

    foreach ($font in $fontFiles) {
        try {
            $fontName = $font.BaseName
            $fontFileName = $font.Name
            $destinationPath = Join-Path $FontsFolder $fontFileName

            # Check if font is already installed
            $registryValue = Get-ItemProperty -Path $FontRegistryPath -Name "$fontName (TrueType)" -ErrorAction SilentlyContinue
            
            if ($registryValue -and (Test-Path $destinationPath)) {
                Write-ColorOutput "  [SKIP] $fontFileName (already installed)" "Yellow"
                $skippedCount++
                continue
            }

            # Copy font file to Fonts folder
            Copy-Item -Path $font.FullName -Destination $destinationPath -Force

            # Register font in registry
            $fontRegistryName = "$fontName (TrueType)"
            New-ItemProperty -Path $FontRegistryPath -Name $fontRegistryName -Value $fontFileName -PropertyType String -Force | Out-Null

            Write-ColorOutput "  [OK] $fontFileName" "Green"
            $installedCount++
        }
        catch {
            Write-ColorOutput "  [ERROR] Failed to install $fontFileName : $_" "Red"
        }
    }

    # Summary
    Write-ColorOutput "`n=== Installation Summary ===" "Cyan"
    Write-ColorOutput "Fonts installed: $installedCount" "Green"
    Write-ColorOutput "Fonts skipped: $skippedCount" "Yellow"
    Write-ColorOutput "`nJetBrains Mono Nerd Font installation completed!" "Cyan"
    Write-ColorOutput "Note: You may need to restart applications to see the new fonts.`n" "Yellow"

}
catch {
    Write-ColorOutput "`n[ERROR] Installation failed: $_" "Red"
    exit 1
}
finally {
    # Clean up temporary files
    Remove-TempFiles
}
