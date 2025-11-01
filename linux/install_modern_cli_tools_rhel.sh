#!/usr/bin/env bash
# Modern CLI Tools Installation Script for RHEL 8/9 (Improved)
# Installs: bat, eza, ncdu, btop, lazygit, fd, ripgrep, tealdeer (tldr), and duf
# Downloads release archives from GitHub and installs to /usr/local/bin

set -euo pipefail

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) ARCH_PATTERN="x86_64" ;;
  aarch64|arm64) ARCH_PATTERN="(aarch64|arm64)" ;;
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

function github_latest_asset_url() {
  local repo="$1"
  local pattern="$2"
  local url
  
  # Use --fail to get proper exit codes
  url=$(curl -sSf "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
    | grep -Po '"browser_download_url": "\K[^"]+' \
    | grep -E "$pattern" \
    | head -n1 || true)
  
  echo "$url"
}

function download_asset() {
  local url="$1"
  local out="$2"
  
  if [[ -z "$url" ]]; then
    echo "No download URL provided"
    return 1
  fi
  
  echo "Downloading: $url"
  if ! curl -L --fail -sS --connect-timeout 30 --max-time 300 -o "$out" "$url"; then
    echo "Download failed"
    return 1
  fi
  return 0
}

function install_from_tarball() {
  local tarfile="$1"
  local bin_name="$2"
  local install_as="${3:-$bin_name}"
  
  local extract_dir="$TMPDIR/extract-$$"
  mkdir -p "$extract_dir"
  
  echo "Extracting $tarfile..."
  case "$tarfile" in
    *.tar.gz|*.tgz) tar -xzf "$tarfile" -C "$extract_dir" 2>/dev/null || return 1 ;;
    *.tar.xz) tar -xJf "$tarfile" -C "$extract_dir" 2>/dev/null || return 1 ;;
    *.zip) unzip -q "$tarfile" -d "$extract_dir" 2>/dev/null || return 1 ;;
    *) echo "Unknown archive type: $tarfile"; return 1 ;;
  esac
  
  local src
  # Find executable binary
  src=$(find "$extract_dir" -type f -name "$bin_name" -executable 2>/dev/null | head -n1 || true)
  
  if [[ -z "$src" ]]; then
    # Fallback: find by name without execute permission
    src=$(find "$extract_dir" -type f -name "$bin_name" 2>/dev/null | head -n1 || true)
  fi
  
  if [[ -z "$src" ]]; then
    echo "Could not find binary '$bin_name' in archive"
    return 1
  fi
  
  echo "Installing $(basename "$src") to /usr/local/bin/$install_as"
  sudo install -m 755 "$src" "/usr/local/bin/$install_as"
  
  # Cleanup this extraction
  rm -rf "$extract_dir"
  return 0
}

function install_from_rpm() {
  local rpmfile="$1"
  local extract_dir="$TMPDIR/rpm-extract-$$"
  
  if ! command -v rpm2cpio >/dev/null 2>&1; then
    echo "rpm2cpio not found"
    return 1
  fi
  
  mkdir -p "$extract_dir"
  echo "Extracting RPM..."
  
  (cd "$extract_dir" && rpm2cpio "$rpmfile" | cpio -idm 2>/dev/null) || return 1
  
  local src
  src=$(find "$extract_dir" -type f \( -path "*/usr/bin/*" -o -path "*/usr/local/bin/*" \) -executable 2>/dev/null | head -n1 || true)
  
  if [[ -n "$src" ]]; then
    local dest_name=$(basename "$src")
    echo "Installing $dest_name from RPM"
    sudo install -m 755 "$src" "/usr/local/bin/$dest_name"
    rm -rf "$extract_dir"
    return 0
  fi
  
  echo "No executable found in RPM"
  rm -rf "$extract_dir"
  return 1
}

function install_from_deb() {
  local debfile="$1"
  local extract_dir="$TMPDIR/deb-extract-$$"
  
  if ! command -v ar >/dev/null 2>&1; then
    echo "'ar' command not available"
    return 1
  fi
  
  mkdir -p "$extract_dir"
  cd "$extract_dir"
  
  ar x "$debfile" 2>/dev/null || return 1
  
  local datafile
  datafile=$(ls -1 | grep 'data\.tar' | head -n1 || true)
  
  if [[ -z "$datafile" ]]; then
    echo "No data archive found in .deb"
    cd - >/dev/null
    rm -rf "$extract_dir"
    return 1
  fi
  
  tar -xf "$datafile" 2>/dev/null || return 1
  
  local src
  src=$(find . -type f \( -path "*/usr/bin/*" -o -path "*/usr/local/bin/*" \) -executable 2>/dev/null | head -n1 || true)
  
  if [[ -n "$src" ]]; then
    local dest_name=$(basename "$src")
    echo "Installing $dest_name from .deb"
    sudo install -m 755 "$src" "/usr/local/bin/$dest_name"
    cd - >/dev/null
    rm -rf "$extract_dir"
    return 0
  fi
  
  echo "No executable found in .deb"
  cd - >/dev/null
  rm -rf "$extract_dir"
  return 1
}

function install_tool() {
  local tool_name="$1"
  local cmd_name="${2:-$1}"
  local repo="$3"
  local pattern="$4"
  local install_as="${5:-$cmd_name}"
  
  echo_header "Installing $tool_name"
  
  if command -v "$cmd_name" >/dev/null 2>&1; then
    echo "$tool_name already installed, skipping"
    INSTALL_STATUS["$tool_name"]="skipped"
    return 0
  fi
  
  local url
  url=$(github_latest_asset_url "$repo" "$pattern")
  
  if [[ -z "$url" ]]; then
    echo "No suitable asset found for $tool_name"
    INSTALL_STATUS["$tool_name"]="failed"
    return 1
  fi
  
  local ext="${url##*.}"
  local out="$TMPDIR/${tool_name}.${ext}"
  
  if ! download_asset "$url" "$out"; then
    INSTALL_STATUS["$tool_name"]="failed"
    return 1
  fi
  
  case "$ext" in
    gz|tgz)
      if install_from_tarball "$out" "$cmd_name" "$install_as"; then
        echo "[OK] $tool_name installed"
        INSTALL_STATUS["$tool_name"]="success"
      else
        echo "[FAIL] $tool_name installation failed"
        INSTALL_STATUS["$tool_name"]="failed"
      fi
      ;;
    rpm)
      if install_from_rpm "$out"; then
        echo "[OK] $tool_name installed"
        INSTALL_STATUS["$tool_name"]="success"
      else
        echo "[FAIL] $tool_name installation failed"
        INSTALL_STATUS["$tool_name"]="failed"
      fi
      ;;
    deb)
      if install_from_deb "$out"; then
        echo "[OK] $tool_name installed"
        INSTALL_STATUS["$tool_name"]="success"
      else
        echo "[FAIL] $tool_name installation failed"
        INSTALL_STATUS["$tool_name"]="failed"
      fi
      ;;
    *)
      echo "Unknown file extension: $ext"
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
else
  echo "Cannot detect OS. Proceeding anyway."
fi

echo ""
echo "This script will download release archives from GitHub"
echo "and install binaries to /usr/local/bin with sudo."
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
  echo "Please install them and try again."
  exit 1
fi

# Install each tool
install_tool "bat" "bat" "sharkdp/bat" "${ARCH_PATTERN}.*(unknown-linux-gnu|unknown-linux-musl)\\.(tar\\.gz|tgz)"
install_tool "eza" "eza" "eza-community/eza" "linux.*${ARCH_PATTERN}.*(tar\\.gz|tgz)"
install_tool "lazygit" "lazygit" "jesseduffield/lazygit" "Linux_${ARCH_PATTERN}\\.(tar\\.gz|tgz)"
install_tool "btop" "btop" "aristocratos/btop" "${ARCH_PATTERN}.*linux.*(tar\\.gz|tgz)"
install_tool "fd" "fd" "sharkdp/fd" "${ARCH_PATTERN}.*(unknown-linux-gnu|unknown-linux-musl)\\.(tar\\.gz|tgz)"
install_tool "ripgrep" "rg" "BurntSushi/ripgrep" "${ARCH_PATTERN}.*(unknown-linux-gnu|unknown-linux-musl)\\.(tar\\.gz|tgz)"
install_tool "tealdeer" "tealdeer" "dbrgn/tealdeer" "${ARCH_PATTERN}.*linux.*\\.(tar\\.gz|tgz)" "tldr"
install_tool "duf" "duf" "muesli/duf" "linux_(amd64|${ARCH_PATTERN}).*(tar\\.gz|tgz|deb)"

# ncdu - special case (build from source if needed)
echo_header "Installing ncdu"
if command -v ncdu >/dev/null 2>&1; then
  echo "ncdu already installed, skipping"
  INSTALL_STATUS["ncdu"]="skipped"
else
  echo "Attempting to build ncdu from source..."
  
  if ! command -v gcc >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
    echo "Build tools (gcc, make) not found. Skipping."
    echo "To build ncdu, install: sudo dnf install -y gcc make ncurses-devel"
    INSTALL_STATUS["ncdu"]="failed"
  else
    # Check for ncurses-devel
    if ! ldconfig -p | grep -q libncursesw.so; then
      echo "ncurses library not found. Install with: sudo dnf install -y ncurses-devel"
      INSTALL_STATUS["ncdu"]="failed"
    else
      srcurl="https://dev.yorhel.nl/download/ncdu-1.19.tar.gz"
      srcfile="$TMPDIR/ncdu-src.tar.gz"
      
      if download_asset "$srcurl" "$srcfile"; then
        build_dir="$TMPDIR/ncdu-build"
        mkdir -p "$build_dir"
        tar -xzf "$srcfile" -C "$build_dir" --strip-components=1
        
        if (cd "$build_dir" && ./configure --prefix=/usr/local && make); then
          sudo make -C "$build_dir" install
          echo "[OK] ncdu built and installed"
          INSTALL_STATUS["ncdu"]="success"
        else
          echo "[FAIL] ncdu build failed"
          INSTALL_STATUS["ncdu"]="failed"
        fi
      else
        echo "[FAIL] ncdu source download failed"
        INSTALL_STATUS["ncdu"]="failed"
      fi
    fi
  fi
fi

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

for tool in "${!cmd_map[@]}"; do
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

for tool in "${!INSTALL_STATUS[@]}"; do
  case "${INSTALL_STATUS[$tool]}" in
    success) ((success++)) ;;
    failed) ((failed++)) ;;
    skipped) ((skipped++)) ;;
  esac
done

echo "Successfully installed: $success"
echo "Already installed (skipped): $skipped"
echo "Failed: $failed"
echo ""
echo "Installed binaries are in /usr/local/bin"
echo ""

if [[ $failed -gt 0 ]]; then
  echo "Some tools failed to install. Check the output above for details."
  exit 1
fi

exit 0