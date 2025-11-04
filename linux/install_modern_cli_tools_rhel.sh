#!/bin/zsh
# Modern CLI Tools Installation Script for RHEL 8/9 (Direct Download Version)
# Installs: bat, eza, ncdu, btop, lazygit, fd, ripgrep, tealdeer (tldr), and duf
# Uses direct download URLs to avoid GitHub API rate limiting

set -euo pipefail

# ============================================================================
# VERSION CONFIGURATION
# Update these versions to install newer releases
# ============================================================================
BAT_VERSION="0.26.0"
EZA_VERSION="0.23.4"
LAZYGIT_VERSION="0.45.0"
FD_VERSION="10.2.0"
RIPGREP_VERSION="14.1.1"
TEALDEER_VERSION="1.7.1"
DUF_VERSION="0.9.1"
BTOP_VERSION="1.4.5"
NCDU_VERSION="2.9.1"

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) ARCH_SUFFIX="x86_64" ;;
  aarch64|arm64) ARCH_SUFFIX="aarch64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Create unique temporary directory
TMPDIR="/tmp/modern-cli-install-$$"
mkdir -p "$TMPDIR"

# Track installation results
declare -A INSTALL_STATUS

function cleanup {
  echo_header "Cleaning up $TMPDIR"
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

function echo_header {
  echo ""
  echo "=================================="
  echo " $1"
  echo "=================================="
}

function download_and_install() {
  local tool_name="$1"
  local cmd_name="$2"
  local url="$3"
  local install_as="${4:-$cmd_name}"
  
  echo_header "Installing $tool_name"
  
  if command -v "$cmd_name" >/dev/null 2>&1; then
    echo "$tool_name already installed, skipping"
    INSTALL_STATUS["$tool_name"]="skipped"
    return 0
  fi
  
  # Determine file type from URL
  local ext
  case "$url" in
    *.tar.gz) ext="tar.gz" ;;
    *.tgz) ext="tgz" ;;
    *.tar.xz) ext="tar.xz" ;;
    *.tbz) ext="tbz" ;;
    *.tar.bz2) ext="tar.bz2" ;;
    *.zip) ext="zip" ;;
    *.rpm) ext="rpm" ;;
    *-musl) ext="musl" ;;
    *) ext="${url##*.}" ;;
  esac
  
  local outfile="$TMPDIR/${tool_name}.${ext}"
  
  echo "Downloading: $url"
  if ! curl -L --fail -sS --connect-timeout 30 --max-time 300 -o "$outfile" "$url"; then
    echo "[FAIL] Download failed"
    INSTALL_STATUS["$tool_name"]="failed"
    return 1
  fi
  
  # Extract and install based on file type
  case "$ext" in
    tar.gz|tgz)
      local extract_dir="$TMPDIR/extract-${tool_name}"
      mkdir -p "$extract_dir"
      echo "Extracting..."
      tar -xzf "$outfile" -C "$extract_dir" 2>/dev/null || {
        echo "[FAIL] Extraction failed"
        INSTALL_STATUS["$tool_name"]="failed"
        return 1
      }

      # Find the binary
      local binary
      binary=$(find "$extract_dir" -type f -name "$cmd_name" | head -n1)

      if [[ -z "$binary" ]]; then
        echo "[FAIL] Binary not found in archive"
        INSTALL_STATUS["$tool_name"]="failed"
        return 1
      fi

      echo "Installing to /usr/local/bin/$install_as"
      sudo install -m 755 "$binary" "/usr/local/bin/$install_as"
      echo "[OK] $tool_name installed"
      INSTALL_STATUS["$tool_name"]="success"
      ;;

    tbz|tar.bz2)
      local extract_dir="$TMPDIR/extract-${tool_name}"
      mkdir -p "$extract_dir"
      echo "Extracting..."
      tar -xjf "$outfile" -C "$extract_dir" 2>/dev/null || {
        echo "[FAIL] Extraction failed"
        INSTALL_STATUS["$tool_name"]="failed"
        return 1
      }

      # Find the binary
      local binary
      binary=$(find "$extract_dir" -type f -name "$cmd_name" -executable | head -n1)

      if [[ -z "$binary" ]]; then
        # Try without -executable flag
        binary=$(find "$extract_dir" -type f -name "$cmd_name" | head -n1)
      fi

      if [[ -z "$binary" ]]; then
        echo "[FAIL] Binary not found in archive"
        INSTALL_STATUS["$tool_name"]="failed"
        return 1
      fi

      echo "Installing to /usr/local/bin/$install_as"
      sudo install -m 755 "$binary" "/usr/local/bin/$install_as"
      echo "[OK] $tool_name installed"
      INSTALL_STATUS["$tool_name"]="success"
      ;;
      
    musl)
      # Single binary file
      echo "Installing to /usr/local/bin/$install_as"
      sudo install -m 755 "$outfile" "/usr/local/bin/$install_as"
      echo "[OK] $tool_name installed"
      INSTALL_STATUS["$tool_name"]="success"
      ;;
    
    rpm)
      # RPM package - install with rpm or yum
      echo "Installing RPM package..."
      if sudo rpm -Uvh "$outfile" 2>/dev/null; then
        echo "[OK] $tool_name installed"
        INSTALL_STATUS["$tool_name"]="success"
      else
        echo "[FAIL] RPM installation failed"
        INSTALL_STATUS["$tool_name"]="failed"
      fi
      ;;
      
    *)
      echo "[FAIL] Unsupported file type: $ext"
      INSTALL_STATUS["$tool_name"]="failed"
      ;;
  esac
}

# Main installation starts here
echo_header "Modern CLI Tools Installation for RHEL 8/9"

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  echo "Detected: $NAME $VERSION_ID"
  echo "Architecture: $ARCH"
fi

echo ""
echo "This script uses direct download URLs from GitHub releases."
echo "Binaries will be installed to /usr/local/bin with sudo."
echo ""

# Check for required commands
missing_deps=()
for dep in curl tar sudo; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    missing_deps+=("$dep")
  fi
done

if [[ ${#missing_deps[@]} -gt 0 ]]; then
  echo "ERROR: Missing required commands: ${missing_deps[*]}"
  exit 1
fi

# Install each tool using direct URLs
# Version numbers are defined at the top of the script for easy updates

download_and_install "bat" "bat" \
  "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-${ARCH_SUFFIX}-unknown-linux-gnu.tar.gz"

download_and_install "eza" "eza" \
  "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${ARCH_SUFFIX}-unknown-linux-gnu.tar.gz"

download_and_install "lazygit" "lazygit" \
  "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH_SUFFIX}.tar.gz"

download_and_install "fd" "fd" \
  "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${ARCH_SUFFIX}-unknown-linux-gnu.tar.gz"

download_and_install "ripgrep" "rg" \
  "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-${ARCH_SUFFIX}-unknown-linux-musl.tar.gz"

download_and_install "tealdeer" "tealdeer" \
  "https://github.com/dbrgn/tealdeer/releases/download/v${TEALDEER_VERSION}/tealdeer-linux-${ARCH_SUFFIX}-musl" "tldr"

download_and_install "duf" "duf" \
  "https://github.com/muesli/duf/releases/download/v${DUF_VERSION}/duf_${DUF_VERSION}_linux_amd64.rpm"

# btop - install from GitHub releases
download_and_install "btop" "btop" \
  "https://github.com/aristocratos/btop/releases/download/v${BTOP_VERSION}/btop-x86_64-linux-musl.tbz"

# ncdu - install from pre-built binary
download_and_install "ncdu" "ncdu" \
  "https://dev.yorhel.nl/download/ncdu-${NCDU_VERSION}-linux-${ARCH_SUFFIX}.tar.gz"

# Verification
echo_header "Verification"

declare -A cmd_map=(
  ["bat"]="bat"
  ["eza"]="eza"
  ["ncdu"]="ncdu"
  ["btop"]="btop"
  ["lazygit"]="lazygit"
  ["fd"]="fd"
  ["ripgrep"]="rg"
  ["tealdeer"]="tldr"
  ["duf"]="duf"
)

for tool in ${(k)cmd_map[@]}; do
  cmd="${cmd_map[$tool]}"
  if command -v "$cmd" >/dev/null 2>&1; then
    version=$("$cmd" --version 2>/dev/null | head -n1 || echo "installed")
    printf "[OK]  %-12s -> %s\n" "$tool" "$version"
  else
    printf "[MISS] %-12s -> not found\n" "$tool"
  fi
done

# Summary
echo_header "Installation Summary"
echo ""
success=0
failed=0
skipped=0

# Check if INSTALL_STATUS has any entries before iterating
if [[ ${#INSTALL_STATUS[@]} -gt 0 ]]; then
  for tool in ${(k)INSTALL_STATUS[@]}; do
    case "${INSTALL_STATUS[$tool]}" in
      success) success=$((success + 1)) ;;
      failed) failed=$((failed + 1)) ;;
      skipped) skipped=$((skipped + 1)) ;;
    esac
  done
fi

printf "Successfully installed: %d\n" "$success"
printf "Already installed (skipped): %d\n" "$skipped"
printf "Failed: %d\n" "$failed"
echo ""
echo "Installed binaries are in /usr/local/bin"
echo ""

if [[ $failed -gt 0 ]]; then
  echo "Note: Some tools failed to install but the core tools should be working."
fi

# Generate modern CLI aliases in ~/.bashrc.d/
echo_header "Configuring ~/.bashrc.d/ integration"

BASHRC_FILE="$HOME/.bashrc"
BASHRC_D_DIR="$HOME/.bashrc.d"
ALIASES_FILE="$BASHRC_D_DIR/modern-cli-tools.sh"

# Create ~/.bashrc.d directory if it doesn't exist
mkdir -p "$BASHRC_D_DIR"

# Check if .bashrc sources from ~/.bashrc.d/
if [[ -f "$BASHRC_FILE" ]]; then
  if ! grep -q '\.bashrc\.d' "$BASHRC_FILE"; then
    echo "Adding ~/.bashrc.d/ sourcing to ~/.bashrc"

    # Backup .bashrc
    BASHRC_BACKUP="${BASHRC_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$BASHRC_FILE" "$BASHRC_BACKUP"
    echo "Backed up ~/.bashrc to $BASHRC_BACKUP"

    # Add bashrc.d sourcing at the end of .bashrc
    cat >> "$BASHRC_FILE" << 'BASHRC_APPEND'

# User specific aliases and functions from ~/.bashrc.d/
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
BASHRC_APPEND
    echo "[OK] Added ~/.bashrc.d/ sourcing to ~/.bashrc"
  else
    echo "[OK] ~/.bashrc already sources from ~/.bashrc.d/"
  fi
else
  echo "[WARN] ~/.bashrc not found, creating a basic one"
  cat > "$BASHRC_FILE" << 'BASHRC_NEW'
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions from ~/.bashrc.d/
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
BASHRC_NEW
  echo "[OK] Created ~/.bashrc with ~/.bashrc.d/ sourcing"
fi

# Backup existing aliases file if it exists
if [[ -f "$ALIASES_FILE" ]]; then
  BACKUP_FILE="${ALIASES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "Backing up existing aliases to $BACKUP_FILE"
  cp "$ALIASES_FILE" "$BACKUP_FILE"
fi

echo ""
echo "Generating ~/.bashrc.d/modern-cli-tools.sh"

# Generate aliases file
cat > "$ALIASES_FILE" << 'ALIASES_EOF'
# ~/.bashrc.d/modern-cli-tools.sh
# Modern CLI Tools Configuration
# Generated by install_cli_tools.sh

# ============================================================================
# Enhanced History Configuration
# ============================================================================

# Don't put duplicate lines or lines starting with space in the history
export HISTCONTROL=ignoreboth

# History size
export HISTSIZE=10000
export HISTFILESIZE=20000

# ============================================================================
# Modern CLI Tool Aliases
# ============================================================================

# eza (modern ls replacement)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=always --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first --git'
    alias la='eza -a --icons --group-directories-first'
    alias l='eza -l --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons --group-directories-first'
    alias lt3='eza --tree --level=3 --icons --group-directories-first'
    alias ltt='eza --tree --icons --group-directories-first'
    alias lsg='eza -la --icons --git --git-ignore --group-directories-first'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls -lh'
fi

# bat (modern cat replacement)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never --style=plain'
    alias ccat='/usr/bin/cat'  # original cat
    alias bathelp='bat --plain --language=help'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# fd (modern find replacement)
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
    alias oldfind='/usr/bin/find'  # original find
fi

# ripgrep (modern grep replacement)
if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
    alias oldgrep='/usr/bin/grep'  # original grep
fi

# btop (system monitor)
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
    alias htop='btop'
fi

# ncdu (disk usage analyzer)
if command -v ncdu >/dev/null 2>&1; then
    alias du='ncdu --color dark'
fi

# duf (disk usage/free utility)
if command -v duf >/dev/null 2>&1; then
    alias df='duf'
fi

# lazygit
if command -v lazygit >/dev/null 2>&1; then
    alias lg='lazygit'
fi

# tealdeer (tldr)
if command -v tldr >/dev/null 2>&1; then
    alias help='tldr'
fi

# ============================================================================
# General Purpose Aliases
# ============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Listing and directories
alias mkdir='mkdir -pv'
alias path='echo -e ${PATH//:/\\n}'

# System information
alias meminfo='free -h'
alias cpuinfo='lscpu'
alias diskspace='df -h'
alias ports='netstat -tulanp'

# Process management
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias psmem='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3 | head -10'

# Network
alias myip='curl -s ifconfig.me'
alias localip='hostname -I | cut -d" " -f1'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i.2'

# Git aliases (if git is available)
if command -v git >/dev/null 2>&1; then
    alias g='git'
    alias gs='git status'
    alias ga='git add'
    alias gaa='git add --all'
    alias gc='git commit'
    alias gcm='git commit -m'
    alias gp='git push'
    alias gpl='git pull'
    alias gd='git diff'
    alias gco='git checkout'
    alias gb='git branch'
    alias gl='git log --oneline --graph --decorate --all'
    alias gls='git log --oneline --graph --decorate'
fi

# Quick edits
alias bashrc='${EDITOR:-vi} ~/.bashrc'
alias reload='source ~/.bashrc && echo "Bash config reloaded!"'

# Directory shortcuts
alias home='cd ~'
alias downloads='cd ~/Downloads 2>/dev/null || cd ~'
alias documents='cd ~/Documents 2>/dev/null || cd ~'
alias desktop='cd ~/Desktop 2>/dev/null || cd ~'

# File operations
alias h='history'
alias j='jobs -l'
alias now='date +"%T"'
alias nowdate='date +"%Y-%m-%d"'

# Make commonly used commands more verbose
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# System updates (RHEL/CentOS)
alias update='sudo dnf update'
alias upgrade='sudo dnf upgrade'
alias install='sudo dnf install'
alias search='dnf search'

# ============================================================================
# Custom Functions
# ============================================================================

# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find process by name
psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$@"
}

# Create backup of file
backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# Quick directory size
dirsize() {
    du -sh "${1:-.}" 2>/dev/null
}

# ============================================================================
# Environment Variables
# ============================================================================

# Less options for better viewing
export LESS='-R -F -X'

# ============================================================================
# Welcome Message
# ============================================================================

# Only show message on interactive shells and if not already shown
if [[ $- == *i* ]] && [[ -z "$MODERN_CLI_TOOLS_LOADED" ]]; then
    echo "Modern CLI Tools loaded! Type 'alias' to see all aliases."
    export MODERN_CLI_TOOLS_LOADED=1
fi

ALIASES_EOF

echo "[OK] Generated ~/.bashrc.d/modern-cli-tools.sh"
echo ""

# Source the bashrc to activate immediately if running in an interactive shell
if [[ $- == *i* ]]; then
  echo "Activating new configuration..."
  source "$HOME/.bashrc"
  echo ""
  echo "Modern CLI tools are now active!"
else
  echo "To activate the new configuration, run: source ~/.bashrc"
  echo "Or log out and log back in."
fi

echo ""
echo "To disable these aliases, simply: rm ~/.bashrc.d/modern-cli-tools.sh"

exit 0
