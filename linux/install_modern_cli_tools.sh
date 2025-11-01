#!/usr/bin/env bash
# Modern CLI Tools Installation Script for Debian 12/13
# Installs: bat, eza, ncdu, btop, lazygit, fd, ripgrep, tldr, and duf

set -euo pipefail

SCRIPT_DIR="$(pwd)"
TMPDIR="/tmp/modern-cli-install-$$"
mkdir -p "$TMPDIR"

function cleanup {
  echo "Cleaning up temporary files..."
  rm -rf "$TMPDIR"
  cd "$SCRIPT_DIR"
}
trap cleanup EXIT

function echo_header {
  echo ""
  echo "=================================="
  echo " $1"
  echo "=================================="
}

echo_header "Modern CLI Tools Installation"

# Check if running as non-root (we'll use sudo)
if [[ $EUID -eq 0 ]]; then
   echo "Please run this script as a normal user (it will use sudo when needed)"
   exit 1
fi

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install tools available via apt
echo_header "Installing tools from apt repositories"
sudo apt install -y bat ncdu btop ripgrep tldr fd-find

# Install eza
echo_header "Installing eza"
if command -v eza >/dev/null 2>&1; then
  echo "eza already installed, skipping"
else
  cd "$TMPDIR"
  if curl -fsSL -o eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"; then
    tar xf eza.tar.gz
    sudo install -m 755 eza /usr/local/bin/
    echo "✓ eza installed"
  else
    echo "✗ eza download failed"
  fi
fi

# Install lazygit
echo_header "Installing lazygit"
if command -v lazygit >/dev/null 2>&1; then
  echo "lazygit already installed, skipping"
else
  cd "$TMPDIR"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
  if [[ -z "$LAZYGIT_VERSION" ]]; then
    echo "✗ Could not determine lazygit version"
  elif curl -fsSL -o lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"; then
    tar xf lazygit.tar.gz
    sudo install -m 755 lazygit /usr/local/bin/
    echo "✓ lazygit installed"
  else
    echo "✗ lazygit download failed"
  fi
fi

# Install duf
echo_header "Installing duf"
if command -v duf >/dev/null 2>&1; then
  echo "duf already installed, skipping"
else
  cd "$TMPDIR"
  DUF_VERSION=$(curl -s "https://api.github.com/repos/muesli/duf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
  if [[ -z "$DUF_VERSION" ]]; then
    echo "✗ Could not determine duf version"
  elif curl -fsSL -o duf.deb "https://github.com/muesli/duf/releases/latest/download/duf_${DUF_VERSION}_linux_amd64.deb"; then
    sudo dpkg -i duf.deb
    echo "✓ duf installed"
  else
    echo "✗ duf download failed"
  fi
fi

# Verify installations
echo_header "Verifying installations"

for cmd in batcat:bat eza:eza ncdu:ncdu btop:btop lazygit:lazygit fdfind:fd rg:ripgrep tldr:tldr duf:duf; do
  IFS=':' read -r actual_cmd display_name <<< "$cmd"
  if command -v "$actual_cmd" >/dev/null 2>&1; then
    version=$($actual_cmd --version 2>/dev/null | head -n1 || echo "installed")
    printf "✓ %-10s -> %s\n" "$display_name" "$version"
  else
    printf "✗ %-10s -> not found\n" "$display_name"
  fi
done

echo_header "Installation complete!"
echo ""
echo "Note: On Debian, some tools have different names:"
echo "  - 'bat' is installed as 'batcat'"
echo "  - 'fd' is installed as 'fdfind'"
echo ""
echo "Add these aliases to your ~/.bashrc:"
echo "  alias bat='batcat'"
echo "  alias fd='fdfind'"
echo ""
echo "Then run: source ~/.bashrc"