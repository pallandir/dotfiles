#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting Ubuntu setup..."

# ----------------------
# Helper functions
# ----------------------
apt_install_if_missing() {
  pkg="$1"
  if ! dpkg -s "$pkg" &> /dev/null; then
    echo "Installing $pkg ..."
    sudo apt-get install -y "$pkg"
  else
    echo "$pkg already installed"
  fi
}

git_clone_if_missing() {
  repo="$1"
  target="$2"
  if [ ! -d "$target" ]; then
    echo "Cloning $repo into $target ..."
    git clone "$repo" "$target"
  else
    echo "Directory $target already exists"
  fi
}

command_exists() {
  command -v "$1" &> /dev/null
}

# ----------------------
# Update APT
# ----------------------
echo "Updating APT ..."
sudo apt-get update -y

# ----------------------
# Install base packages
# ----------------------
echo "Installing base packages..."
apt_install_if_missing zsh
apt_install_if_missing git
apt_install_if_missing flatpak
apt_install_if_missing curl
apt_install_if_missing wget

# ----------------------
# Build dependencies for Neovim and Treesitter
# ----------------------
echo "Installing build dependencies..."
apt_install_if_missing build-essential
apt_install_if_missing cmake
apt_install_if_missing unzip
apt_install_if_missing gettext

# ----------------------
# CLI tools for Neovim IDE
# ----------------------
echo "Installing CLI tools for Neovim..."
apt_install_if_missing ripgrep
apt_install_if_missing fd-find
apt_install_if_missing fzf
apt_install_if_missing xclip

# ----------------------
# Install Neovim (latest from unstable PPA for 0.11+)
# ----------------------
echo "Installing Neovim..."
if ! command_exists nvim || [[ "$(nvim --version | head -n1 | grep -oP '\d+\.\d+' | head -1)" < "0.11" ]]; then
  echo "Adding Neovim unstable PPA and installing latest..."
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo apt-get update -y
  sudo apt-get install -y neovim
else
  echo "Neovim $(nvim --version | head -n1) already installed"
fi

# ----------------------
# Node.js (for LSPs and formatters)
# ----------------------
echo "Installing Node.js..."
if ! command_exists node; then
  echo "Installing Node.js via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node.js $(node --version) already installed"
fi

# Install neovim npm package for Node.js provider
echo "Installing Neovim Node.js provider..."
if ! npm list -g neovim &>/dev/null; then
  sudo npm install -g neovim
else
  echo "Neovim npm package already installed"
fi

# Install tree-sitter-cli (required for nvim-treesitter)
echo "Installing tree-sitter-cli..."
if ! command_exists tree-sitter; then
  sudo npm install -g tree-sitter-cli
else
  echo "tree-sitter-cli already installed"
fi

# ----------------------
# Python
# ----------------------
echo "Installing Python development tools..."
apt_install_if_missing python3
apt_install_if_missing python3-pip
apt_install_if_missing python3-venv
apt_install_if_missing python3-full

# Create Neovim Python venv with pynvim (PEP 668 compliant)
NVIM_VENV="${HOME}/.local/share/nvim/python-venv"
if [ ! -d "$NVIM_VENV" ]; then
  echo "Creating Neovim Python venv..."
  python3 -m venv "$NVIM_VENV"
  "$NVIM_VENV/bin/pip" install --upgrade pip pynvim
  echo "Neovim Python venv created at $NVIM_VENV"
else
  echo "Neovim Python venv already exists"
fi

# ----------------------
# Go
# ----------------------
echo "Installing Go..."
if ! command_exists go; then
  GO_VERSION="1.22.0"
  echo "Downloading Go ${GO_VERSION}..."
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm /tmp/go.tar.gz

  if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' "${HOME}/.profile" 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "${HOME}/.profile"
    echo 'export PATH=$PATH:$HOME/go/bin' >> "${HOME}/.profile"
  fi
  export PATH=$PATH:/usr/local/go/bin
  echo "Go installed: $(go version)"
else
  echo "Go $(go version) already installed"
fi

# ----------------------
# Rust
# ----------------------
echo "Installing Rust..."
if ! command_exists rustc; then
  echo "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "${HOME}/.cargo/env"
  echo "Rust installed: $(rustc --version)"
else
  echo "Rust $(rustc --version) already installed"
fi

# ----------------------
# Tmux
# ----------------------
echo "Installing Tmux..."
apt_install_if_missing tmux

# Install TPM (Tmux Plugin Manager)
TPM_DIR="${HOME}/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "TPM already installed"
fi

# Link tmux config
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TMUX_CONF_SRC="${SCRIPT_DIR}/../tmux/tmux.conf"
TMUX_CONF_TARGET="${HOME}/.tmux.conf"
if [ -f "$TMUX_CONF_SRC" ]; then
  echo "Linking tmux.conf..."
  ln -sf "$(realpath "$TMUX_CONF_SRC")" "$TMUX_CONF_TARGET"
fi

# ----------------------
# OpenCode AI
# ----------------------
echo "Installing OpenCode..."
if ! command_exists opencode; then
  curl -fsSL https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install | bash
else
  echo "OpenCode already installed"
fi

# Install OpenCode configuration
OPENCODE_INSTALL="${SCRIPT_DIR}/../opencode/install.sh"
if [ -f "$OPENCODE_INSTALL" ]; then
  echo "Installing OpenCode configuration..."
  bash "$OPENCODE_INSTALL"
fi

# ----------------------
# Flatpak
# ----------------------
if ! flatpak remotes | grep -q flathub; then
  echo "Adding Flathub repository..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
  echo "Flathub already added"
fi

# ----------------------
# ZSH + Oh My Zsh + Jovial theme
# ----------------------
echo "Configuring zsh and Oh My Zsh..."
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed"
fi

# Install Jovial theme if missing
if [ ! -f "${ZSH_CUSTOM}/themes/jovial.zsh-theme" ]; then
  echo "Installing Jovial theme..."
  git_clone_if_missing https://github.com/zthxxx/jovial "${ZSH_CUSTOM}/themes/jovial"
  cp "${ZSH_CUSTOM}/themes/jovial/jovial.zsh-theme" "${ZSH_CUSTOM}/themes/"
else
  echo "Jovial theme already present"
fi

# Link .zshrc from dotfiles
ZSHRC_SRC="${SCRIPT_DIR}/../.zshrc"
if [ -f "$ZSHRC_SRC" ]; then
  echo "Linking .zshrc..."
  ln -sf "$(realpath "$ZSHRC_SRC")" "${HOME}/.zshrc"
else
  echo "Warning: .zshrc not found in dotfiles"
fi

# Install zsh plugins
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# Set zsh as default shell
if [ "$(basename "$SHELL")" != "zsh" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$(which zsh)" || true
fi

# ----------------------
# Neovim config
# ----------------------
echo "Installing Neovim config..."
NVIM_CONF_REPO="https://github.com/pallandir/neovim.git"
NVIM_TARGET="${HOME}/.config/nvim"
mkdir -p "$(dirname "$NVIM_TARGET")"

if [ ! -d "$NVIM_TARGET" ]; then
  echo "Cloning Neovim config..."
  git_clone_if_missing "$NVIM_CONF_REPO" "$NVIM_TARGET"
else
  echo "Neovim config already exists"
fi

# ----------------------
# Initialize Neovim (install plugins and LSPs)
# ----------------------
echo "Initializing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
echo "Neovim plugins synced (Mason will install LSPs on first launch)"

# ----------------------
# GTK themes
# ----------------------
echo "Installing GTK themes..."
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
THEME_SRC="${SCRIPT_DIR}/../.themes"
GTK3_SRC="${SCRIPT_DIR}/../gtk-3.0"
GTK4_SRC="${SCRIPT_DIR}/../gtk-4.0"

mkdir -p "${HOME}/.themes"
mkdir -p "${HOME}/.config/gtk-3.0"
mkdir -p "${HOME}/.config/gtk-4.0"

if [ -d "$THEME_SRC" ]; then
  cp -rn "$THEME_SRC"/* "${HOME}/.themes/" 2>/dev/null || true
fi
if [ -d "$GTK3_SRC" ]; then
  cp -rn "$GTK3_SRC"/* "${HOME}/.config/gtk-3.0/" 2>/dev/null || true
fi
if [ -d "$GTK4_SRC" ]; then
  cp -rn "$GTK4_SRC"/* "${HOME}/.config/gtk-4.0/" 2>/dev/null || true
fi

echo "GTK themes copied successfully"

# ----------------------
echo ""
echo "==> Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or run 'source ~/.zshrc')"
echo "  2. Open tmux and run 'prefix + I' to install plugins"
echo "  3. Open Neovim and wait for Mason to install LSPs/formatters"
echo "  4. Run :checkhealth in Neovim to verify everything is working"
echo ""
