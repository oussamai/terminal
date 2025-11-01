# Modern CLI Tools - Quick Reference

## File Listing & Navigation

### eza (replaces ls)
```bash
ll              # Long listing with icons and git status
la              # Long listing, all files
ls              # Basic listing with icons
lt              # Tree view (2 levels)
```

### bat (replaces cat)
```bash
cat filename    # View file with syntax highlighting
bat -A filename # Show all characters including non-printable
bat -p filename # Plain output (no decorations)
```

## System Monitoring

### btop (replaces top/htop)
```bash
btop            # Launch resource monitor
```

**In btop:**
- `F2` or `ESC`: Menu
- `q`: Quit
- `k`: Kill process
- `i`: Sort by PID
- `p`: Sort by CPU
- `m`: Sort by memory

### ncdu (disk usage)
```bash
ncdu            # Analyze current directory
ncdu /path      # Analyze specific path
```

**In ncdu:**
- `↑↓`: Navigate
- `Enter`: Enter directory
- `d`: Delete selected item
- `q`: Quit
- `?`: Help

## Git Operations

### lazygit
```bash
lg              # Launch lazygit (alias)
lazygit         # Launch lazygit
```

**Key shortcuts:**
- `1`: Status
- `2`: Files
- `3`: Branches
- `4`: Commits
- `5`: Stash
- `Space`: Stage/unstage
- `c`: Commit
- `P`: Push
- `p`: Pull
- `x`: Command menu
- `?`: Help

## Search & Find

### fd (replaces find)
```bash
fdfind pattern          # Find files matching pattern
fdfind -e txt           # Find all .txt files
fdfind -H pattern       # Include hidden files
```

### ripgrep (rg - replaces grep)
```bash
rg "pattern"            # Search recursively
rg -i "pattern"         # Case-insensitive search
rg -t py "pattern"      # Search only Python files
rg -l "pattern"         # List files with matches
```

## Disk Usage

### duf (disk free)
```bash
duf                     # Show disk usage
duf --only local        # Show only local disks
```

## Help & Documentation

### tldr (simplified man pages)
```bash
tldr command            # Get simple examples
tldr tar                # Examples for tar
tldr -u                 # Update cache
```

## Color Customization

Current EZA_COLORS configuration provides bright, visible colors:
- Directories: Bold blue
- Executables: Bold green
- User/group/dates: Light gray (249)
- Read permissions: Bright yellow (220)
- Write permissions: Bright red (203)
- Execute permissions: Bright green (148)

## Useful Combinations

```bash
# Find large files
ncdu / | head -20

# Search in git-tracked files only
rg "pattern" $(git ls-files)

# View colored log files
cat /var/log/syslog

# Monitor system while running intensive task
btop &
your_intensive_command

# Interactive git workflow
cd your_repo && lg
```

## Aliases in .bashrc

```bash
alias ll='eza -lA --header --icons --git --color=always'
alias cat='batcat -p'
alias top='btop'
alias htop='btop'
alias lg='lazygit'
alias du='ncdu --color dark -rr -x'
alias h='history'
```

## Quick Install Commands

```bash
# All at once
sudo apt install bat ncdu btop ripgrep tldr fd-find

# Or use the installation script
chmod +x install_modern_cli_tools.sh
./install_modern_cli_tools.sh
```

## Troubleshooting

### bat shows as batcat
On Debian, the binary is named `batcat` to avoid conflicts. The alias handles this.

### fd shows as fdfind
Same reason - use the alias `fd='fdfind'` in your .bashrc

### Colors too dark
1. Check your terminal color scheme
2. Adjust EZA_COLORS in .bashrc
3. Try: `ll --color-scale=all`

### eza not found after install
Run: `source ~/.bashrc` or restart your terminal
