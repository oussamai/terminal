# Create profile if it doesn't exist
# if (!(Test-Path -Path $PROFILE)) {
#     New-Item -Path $PROFILE -ItemType File
# }
# Open profile for editing
# notepad $PROFILE
# write-output $PROFILE
# C:\Users\osiris\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

function ll {
    eza -lA --header --icons --color=always --color-scale @args
}

Function Update-AllPackages {
    [CmdletBinding()]
    param(
        [switch]$SkipWinget,
        [switch]$SkipStore,
        [switch]$SkipChocolatey
    )

    Write-Host "Starting package updates..." -ForegroundColor Cyan
    
    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    # Update winget packages
    if (-not $SkipWinget) {
        Write-Host "`n== Updating winget packages ==" -ForegroundColor Cyan
        try {
            # Check if winget is available
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget upgrade --all --silent --include-unknown
            }
            else {
                Write-Host "Winget is not installed or not available in PATH" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error updating winget packages: $_" -ForegroundColor Red
        }
    }
    
    # Update Microsoft Store apps
    if (-not $SkipStore) {
        Write-Host "`n== Updating Microsoft Store apps ==" -ForegroundColor Cyan
        try {
            Write-Host "Note: Microsoft Store app updates may require manual interaction" -ForegroundColor Yellow
            Write-Host "Consider checking the Microsoft Store app for updates" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Error checking for Microsoft Store updates: $_" -ForegroundColor Red
        }
    }
    
    # Update Chocolatey packages
    if (-not $SkipChocolatey) {
        Write-Host "`n== Updating Chocolatey packages ==" -ForegroundColor Cyan
        try {
            # Check if Chocolatey is available
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                if ($isAdmin) {
                    choco upgrade all -y
                }
                else {
                    Write-Host "Chocolatey requires admin privileges. Please run PowerShell as Administrator to update these packages." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Chocolatey is not installed or not available in PATH" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error updating Chocolatey packages: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nUpdate process completed!" -ForegroundColor Green
}

Set-Alias -Name Upgrade-All -Value Update-AllPackages