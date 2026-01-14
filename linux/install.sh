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

# ----------------------
# Update APT
# ----------------------
echo "Updating APT ..."
sudo apt-get update -y

# ----------------------
# Install packages
# ----------------------
echo "Installing base packages..."
apt_install_if_missing zsh
apt_install_if_missing git
apt_install_if_missing neovim
apt_install_if_missing flatpak
apt_install_if_missing curl
apt_install_if_missing wget

# add flathub repository if missing
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

# Write minimal ~/.zshrc with Jovial
if ! grep -q "ZSH_THEME=\"jovial\"" "${HOME}/.zshrc" 2> /dev/null; then
  echo "Writing ~/.zshrc (with Jovial theme)..."
  cat > "${HOME}/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="jovial"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"
EOF
else
  echo "~/.zshrc already configured for Jovial"
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
NVIM_CONF_REPO="https://github.com/your/repo.git"  # adjust
NVIM_TARGET="${HOME}/.config/nvim"
mkdir -p "$(dirname "$NVIM_TARGET")"

if [ ! -d "$NVIM_TARGET" ]; then
  echo "Cloning Neovim config..."
  git_clone_if_missing "$NVIM_CONF_REPO" "$NVIM_TARGET"
else
  echo "Neovim config already exists"
fi

# ----------------------
# GTK themes
# ----------------------
echo "Installing GTK themes..."
THEME_SRC="$(realpath "$(dirname "$0")/../.themes")"
GTK3_SRC="$(realpath "$(dirname "$0")/../gtk-3.0")"
GTK4_SRC="$(realpath "$(dirname "$0")/../gtk-4.0")"

# Create user theme directories
mkdir -p "${HOME}/.themes"
mkdir -p "${HOME}/.config/gtk-3.0"
mkdir -p "${HOME}/.config/gtk-4.0"

# Copy themes idempotently
cp -rn "$THEME_SRC"/* "${HOME}/.themes/" || true
cp -rn "$GTK3_SRC"/* "${HOME}/.config/gtk-3.0/" || true
cp -rn "$GTK4_SRC"/* "${HOME}/.config/gtk-4.0/" || true

echo "GTK themes copied successfully"

# ----------------------
echo "==> Setup complete! Log out/in for GTK theme to fully apply."

