#!/bin/bash
# Modern CLI Tools Installation Script for Debian 12/13
# This script installs: bat, eza, ncdu, btop, lazygit, fd, ripgrep, tldr, and duf

set -e  # Exit on error

echo "=================================="
echo "Modern CLI Tools Installation"
echo "=================================="
echo ""

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install tools available via apt
echo ""
echo "Installing tools from apt repositories..."
sudo apt install -y bat ncdu btop ripgrep tldr fd-find

# Install eza
echo ""
echo "Installing eza..."
cd /tmp
wget -q https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
tar xf eza_x86_64-unknown-linux-gnu.tar.gz
sudo mv eza /usr/local/bin/
rm eza_x86_64-unknown-linux-gnu.tar.gz
echo "✓ eza installed"

# Install lazygit
echo ""
echo "Installing lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -sLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz
sudo mv lazygit /usr/local/bin/
rm lazygit.tar.gz
echo "✓ lazygit installed"

# Install duf
echo ""
echo "Installing duf..."
DUF_VERSION=$(curl -s "https://api.github.com/repos/muesli/duf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -sLo duf.deb "https://github.com/muesli/duf/releases/latest/download/duf_${DUF_VERSION}_linux_amd64.deb"
sudo dpkg -i duf.deb
rm duf.deb
echo "✓ duf installed"

# Verify installations
echo ""
echo "=================================="
echo "Verifying installations..."
echo "=================================="
echo ""

command -v batcat >/dev/null 2>&1 && echo "✓ bat: $(batcat --version | head -n1)" || echo "✗ bat: not found"
command -v eza >/dev/null 2>&1 && echo "✓ eza: $(eza --version | head -n1)" || echo "✗ eza: not found"
command -v ncdu >/dev/null 2>&1 && echo "✓ ncdu: $(ncdu --version | head -n1)" || echo "✗ ncdu: not found"
command -v btop >/dev/null 2>&1 && echo "✓ btop: $(btop --version | head -n1)" || echo "✗ btop: not found"
command -v lazygit >/dev/null 2>&1 && echo "✓ lazygit: $(lazygit --version | head -n1)" || echo "✗ lazygit: not found"
command -v fdfind >/dev/null 2>&1 && echo "✓ fd: $(fdfind --version | head -n1)" || echo "✗ fd: not found"
command -v rg >/dev/null 2>&1 && echo "✓ ripgrep: $(rg --version | head -n1)" || echo "✗ ripgrep: not found"
command -v tldr >/dev/null 2>&1 && echo "✓ tldr: installed" || echo "✗ tldr: not found"
command -v duf >/dev/null 2>&1 && echo "✓ duf: $(duf --version | head -n1)" || echo "✗ duf: not found"

echo ""
echo "=================================="
echo "Installation complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Backup your current .bashrc: cp ~/.bashrc ~/.bashrc.backup"
echo "2. Update your .bashrc with the new configuration"
echo "3. Run: source ~/.bashrc"
echo ""
echo "Enjoy your modern CLI tools!"
