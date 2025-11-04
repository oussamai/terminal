# Modern CLI Tools Installer for RHEL 8/9

A comprehensive installation script that upgrades your terminal experience with modern CLI alternatives and productivity tools.

## What Gets Installed

| Tool | Replaces | Description |
|------|----------|-------------|
| **bat** | cat | Syntax highlighting and git integration |
| **eza** | ls | Modern file listing with icons and git status |
| **fd** | find | Fast and user-friendly file search |
| **ripgrep (rg)** | grep | Blazing fast recursive search |
| **ncdu** | du | Interactive disk usage analyzer |
| **btop** | top/htop | Beautiful system monitor |
| **duf** | df | Modern disk usage viewer |
| **lazygit** | - | Terminal UI for git commands |
| **tealdeer (tldr)** | man | Simplified command examples |

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/oussamai/terminal/main/linux/install_modern_cli_tools_rhel.sh | zsh
```

The script will:
1. Download and install all tools to `/usr/local/bin`
2. Create `~/.bashrc.d/modern-cli-tools.sh` with aliases and functions
3. Configure `~/.bashrc` to auto-load from `~/.bashrc.d/`

## Requirements

- RHEL 8/9 or compatible (Rocky Linux, AlmaLinux, etc.)
- `curl`, `tar`, and `sudo` installed
- x86_64 or aarch64 architecture

## Features

- **Direct Downloads**: Uses GitHub release URLs to avoid API rate limits
- **Version Management**: All versions defined at the top of script for easy updates
- **Safe Installation**: Checks for existing tools and skips if already installed
- **Auto-Configuration**: Sets up aliases and shell integration automatically
- **Backup Protection**: Backs up existing configuration files before modification

## Configuration

After installation, the script creates helpful aliases:

```bash
ls, ll, la      # eza with icons and git status
cat             # bat with syntax highlighting
find            # fd for faster searches
grep            # ripgrep for blazing speed
top, htop       # btop system monitor
du              # ncdu interactive analyzer
df              # duf disk usage
lg              # lazygit
```

Plus 50+ productivity aliases for navigation, git, system info, and more.

## Customization

Edit version numbers at the top of [install_cli_tools.sh](install_cli_tools.sh:12-20) to install different releases:

```bash
BAT_VERSION="0.26.0"
EZA_VERSION="0.23.4"
LAZYGIT_VERSION="0.45.0"
# ... etc
```

## Uninstalling

To remove aliases and configurations:
```bash
rm ~/.bashrc.d/modern-cli-tools.sh
```

To remove the tools themselves:
```bash
sudo rm /usr/local/bin/{bat,eza,fd,rg,ncdu,btop,duf,lazygit,tldr}
```

## License

MIT
