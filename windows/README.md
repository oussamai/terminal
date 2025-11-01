# How to Create a Permanent `ll` Alias in Windows PowerShell

This document outlines the procedure to create a persistent, Linux-style `ll` alias in Windows PowerShell.

The standard `Set-Alias` cmdlet can only create a simple alias for another command name (e.g., `ll` -> `Get-ChildItem`). It **cannot** be used for aliases that include default arguments (like `--header`, `--icons`, etc.).

The correct method is to create a **function** in your PowerShell profile.

## Prerequisite: Install `eza`

This guide assumes you have [eza](https://eza.rocks/) installed and accessible in your system's `PATH`. If not, you can install it using a package manager:

```powershell
# Using Winget
winget install eza-community.eza
```

## Required fonts for best experience

`eza` renders file icons and some visual elements using Nerd Fonts. For the full visual experience (icons, glyphs and proper alignment) please install the JetBrains Mono Nerd Font included in this repository.

Run the installer script as Administrator on Windows to add the fonts system-wide:

```powershell
# Run from the repository root (Administrator PowerShell)
./Install-JetBrainsNerdFont.ps1
```

After installing the fonts, restart your terminal or any open applications to pick up the new fonts.

## Procedure

### 1. Locate and Open Your Profile

PowerShell stores its settings in a profile script that runs every time it starts. You can open this file in Notepad (or your default editor) by running:

```powershell
notepad $PROFILE
```

> **Note:** If this command gives an error, it just means the file doesn't exist yet. You can create it by running this command first, then try the `notepad $PROFILE` command again:
>
> ```powershell
> New-Item -Path $PROFILE -ItemType File -Force
> ```

### 2. Add the `ll` Function

Instead of an alias, you will create a small function named `ll` that calls `eza` with your desired arguments. Paste the following code into the profile file you just opened:

```powershell
function ll {
    eza -lA --header --icons --color=always --color-scale @args
}
```

**Why this works:**

* `function ll { ... }`: This defines a new command called `ll`.
* `@args`: This special variable is essential. It forwards any additional arguments you type (e.g., `ll C:\Windows`) directly to the `eza` command, making your new `ll` command flexible.

### 3. Save and Reload

1.  Save the `$PROFILE` file in Notepad and close it.
2.  To apply the changes to your *current* terminal session, you must "dot-source" (reload) your profile. Run the following command (note the dot and space at the beginning):

    ```powershell
    . $PROFILE
    ```

Your `ll` command is now permanently active. It will work in your current session and in all new PowerShell terminals you open.

---

## Example Profile (`Microsoft.PowerShell_profile.ps1`)

For reference, here is how the `ll` function fits in with other functions and aliases in a complete profile file.

```powershell
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
            } else {
                Write-Host "Winget is not installed or not available in PATH" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error updating winget packages: $_" -ForegroundColor Red
        }
    }
    
    # Update Microsoft Store apps
    if (-not $SkipStore) {
        Write-Host "`n== Updating Microsoft Store apps ==" -ForegroundColor Cyan
        try {
            Write-Host "Note: Microsoft Store app updates may require manual interaction" -ForegroundColor Yellow
            Write-Host "Consider checking the Microsoft Store app for updates" -ForegroundColor Yellow
        } catch {
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
                } else {
                    Write-Host "Chocolatey requires admin privileges. Please run PowerShell as Administrator to update these packages." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Chocolatey is not installed or not available in PATH" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error updating Chocolatey packages: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nUpdate process completed!" -ForegroundColor Green
}

Set-Alias -Name Upgrade-All -Value Update-AllPackages
```