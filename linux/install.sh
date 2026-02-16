#!/usr/bin/env bash
set -euo pipefail

#####################################
# Globals
#####################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DRY_RUN="${DRY_RUN:-0}"

#####################################
# Platform guard
#####################################

if [[ "$(uname)" != "Linux" ]]; then
  echo -e "${RED}This script is Linux-only.${NC}"
  exit 1
fi

#####################################
# Helpers
#####################################

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${YELLOW}[dry-run] $*${NC}"
  else
    eval "$@"
  fi
}

log_info()  { echo -e "${GREEN}$*${NC}"; }
log_warn()  { echo -e "${YELLOW}$*${NC}"; }
log_err()   { echo -e "${RED}$*${NC}"; }
log_skip()  { echo -e "$*"; }

ensure_symlink() {
  local src dst resolved
  src="$1"
  dst="$2"
  resolved="$(realpath "$src")"
  mkdir -p "$(dirname "$dst")"
  run "ln -sf '$resolved' '$dst'"
}

git_clone_if_missing() {
  local repo="$1" target="$2"
  if [[ ! -d "$target" ]]; then
    run "git clone \"$repo\" \"$target\""
  else
    log_skip "  Directory $target already exists"
  fi
}

apt_install_if_missing() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null; then
    log_skip "  $pkg already installed"
  else
    log_info "  Installing $pkg..."
    run "sudo apt-get install -y \"$pkg\""
  fi
}

command_exists() { command -v "$1" &>/dev/null; }

#####################################
# Component definitions
#####################################

COMPONENTS=(base zsh nvim rust tmux opencode flatpak display-scaling gtk-themes)

declare -A COMP_DESC COMP_DEPS
COMP_DESC=(
  [base]="Base packages (zsh/git/flatpak/curl/build tools)"
  [zsh]="Oh My Zsh + plugins + Jovial theme"
  [nvim]="Neovim + CLI tools + providers + config"
  [rust]="Rust via rustup"
  [tmux]="Tmux + TPM + config"
  [opencode]="OpenCode AI + config"
  [flatpak]="Flathub remote"
  [display-scaling]="Display scaling config (HiDPI)"
  [gtk-themes]="GTK 3/4 themes"
)
COMP_DEPS=(
  [base]=""
  [zsh]="base"
  [nvim]="base"
  [rust]="base"
  [tmux]="base"
  [opencode]=""
  [flatpak]="base"
  [display-scaling]=""
  [gtk-themes]=""
)

#####################################
# Menu + selection + dependency resolution
#####################################

show_menu() {
  echo ""
  echo -e "${BOLD}==========================================="
  echo "  Dotfiles Installer - Linux"
  echo -e "===========================================${NC}"
  echo ""
  echo "Available components:"
  local i=1
  for comp in "${COMPONENTS[@]}"; do
    local dep_info=""
    if [[ -n "${COMP_DEPS[$comp]}" ]]; then
      dep_info=" ${BLUE}[requires: ${COMP_DEPS[$comp]}]${NC}"
    fi
    printf "  %d) %-18s %s%b\n" "$i" "$comp" "${COMP_DESC[$comp]}" "$dep_info"
    ((i++))
  done
  echo ""
  echo "  a) all              Install everything"
  echo ""
  printf "Select components (space/comma-separated, e.g. 1,3,4 or 'a' for all):\n> "
}

parse_selection() {
  local input="$1"

  if [[ -z "$input" || "$input" == "a" || "$input" == "all" ]]; then
    SELECTED=("${COMPONENTS[@]}")
    return
  fi

  SELECTED=()
  IFS=', ' read -ra items <<< "$input"
  for item in "${items[@]}"; do
    item="${item// /}"
    [[ -z "$item" ]] && continue
    if [[ "$item" =~ ^[0-9]+$ ]]; then
      if (( item >= 1 && item <= ${#COMPONENTS[@]} )); then
        SELECTED+=("${COMPONENTS[$((item-1))]}")
      else
        log_err "Invalid number: $item"
        exit 1
      fi
    else
      local found=0
      for comp in "${COMPONENTS[@]}"; do
        if [[ "$comp" == "$item" ]]; then
          SELECTED+=("$comp")
          found=1
          break
        fi
      done
      if (( !found )); then
        log_err "Unknown component: $item"
        exit 1
      fi
    fi
  done
}

resolve_deps() {
  local resolved=()
  for comp in "${SELECTED[@]}"; do
    local dep="${COMP_DEPS[$comp]}"
    if [[ -n "$dep" ]]; then
      local dep_found=0
      for s in "${SELECTED[@]}" "${resolved[@]}"; do
        [[ "$s" == "$dep" ]] && { dep_found=1; break; }
      done
      if (( !dep_found )); then
        log_warn "Auto-adding '$dep' (required by $comp)"
        resolved+=("$dep")
      fi
    fi
  done
  SELECTED=("${resolved[@]}" "${SELECTED[@]}")

  # Deduplicate and reorder according to COMPONENTS
  local ordered=()
  for comp in "${COMPONENTS[@]}"; do
    for s in "${SELECTED[@]}"; do
      if [[ "$s" == "$comp" ]]; then
        ordered+=("$comp")
        break
      fi
    done
  done
  SELECTED=("${ordered[@]}")
}

#####################################
# install_* functions
#####################################

install_base() {
  echo ""
  echo -e "${BOLD}▶ base${NC}"

  log_info "  Updating APT..."
  run "sudo apt-get update -y"

  for pkg in zsh git flatpak curl wget; do
    apt_install_if_missing "$pkg"
  done

  log_info "  Installing build dependencies..."
  for pkg in build-essential cmake unzip gettext rsync; do
    apt_install_if_missing "$pkg"
  done
}

install_zsh() {
  echo ""
  echo -e "${BOLD}▶ zsh${NC}"

  # Oh My Zsh
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log_skip "  Oh My Zsh already installed"
  else
    log_info "  Installing Oh My Zsh..."
    run 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
  fi

  local ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

  # Plugins
  if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
    log_info "  Installing zsh-autosuggestions..."
    run "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
  else
    log_skip "  zsh-autosuggestions already installed"
  fi

  if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
    log_info "  Installing zsh-syntax-highlighting..."
    run "git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
  else
    log_skip "  zsh-syntax-highlighting already installed"
  fi

  # Jovial theme
  if [[ ! -f "${ZSH_CUSTOM}/themes/jovial.zsh-theme" ]]; then
    log_info "  Installing Jovial theme..."
    run "git clone https://github.com/zthxxx/jovial ${ZSH_CUSTOM}/themes/jovial"
    run "cp ${ZSH_CUSTOM}/themes/jovial/jovial.zsh-theme ${ZSH_CUSTOM}/themes/"
  else
    log_skip "  Jovial theme already installed"
  fi

  # .zshrc symlink
  local ZSHRC_SRC="${SCRIPT_DIR}/../.zshrc"
  if [[ -f "$ZSHRC_SRC" ]]; then
    log_info "  Linking .zshrc..."
    ensure_symlink "$ZSHRC_SRC" "${HOME}/.zshrc"
  fi

  # Set zsh as default shell
  if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    log_info "  Changing default shell to zsh..."
    run "chsh -s \"\$(which zsh)\"" || true
  else
    log_skip "  zsh is already the default shell"
  fi
}

install_nvim() {
  echo ""
  echo -e "${BOLD}▶ nvim${NC}"

  # Neovim from PPA
  if command_exists nvim; then
    log_skip "  Neovim already installed"
  else
    log_info "  Adding Neovim PPA and installing..."
    run "sudo add-apt-repository -y ppa:neovim-ppa/unstable"
    run "sudo apt-get update -y"
    run "sudo apt-get install -y neovim"
  fi

  # CLI tools
  for pkg in ripgrep fd-find fzf xclip; do
    apt_install_if_missing "$pkg"
  done

  # Node.js
  if command_exists node; then
    log_skip "  Node.js already installed"
  else
    log_info "  Installing Node.js via NodeSource..."
    run 'curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -'
    run "sudo apt-get install -y nodejs"
  fi

  # neovim npm package
  if npm list -g neovim &>/dev/null; then
    log_skip "  neovim npm package already installed"
  else
    log_info "  Installing neovim npm package..."
    run "sudo npm install -g neovim"
  fi

  # tree-sitter-cli
  if command_exists tree-sitter; then
    log_skip "  tree-sitter-cli already installed"
  else
    log_info "  Installing tree-sitter-cli..."
    run "sudo npm install -g tree-sitter-cli"
  fi

  # Python
  for pkg in python3 python3-pip python3-venv python3-full; do
    apt_install_if_missing "$pkg"
  done

  # Python venv with pynvim
  local NVIM_VENV="${HOME}/.local/share/nvim/python-venv"
  if [[ -d "$NVIM_VENV" ]]; then
    log_skip "  Neovim Python venv already exists"
  else
    log_info "  Creating Neovim Python venv..."
    run "python3 -m venv \"$NVIM_VENV\""
    run "\"$NVIM_VENV/bin/pip\" install --upgrade pip pynvim"
  fi

  # Go
  if command_exists go; then
    log_skip "  Go already installed"
  else
    log_info "  Installing Go..."
    local GO_VERSION="1.22.0"
    run "curl -fsSL \"https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz\" -o /tmp/go.tar.gz"
    run "sudo rm -rf /usr/local/go"
    run "sudo tar -C /usr/local -xzf /tmp/go.tar.gz"
    run "rm /tmp/go.tar.gz"
    if ! grep -q 'export PATH=\$PATH:/usr/local/go/bin' "${HOME}/.profile" 2>/dev/null; then
      run "echo 'export PATH=\$PATH:/usr/local/go/bin' >> \"${HOME}/.profile\""
      run "echo 'export PATH=\$PATH:\$HOME/go/bin' >> \"${HOME}/.profile\""
    fi
    export PATH=$PATH:/usr/local/go/bin
  fi

  # Neovim config
  local NVIM_TARGET="${HOME}/.config/nvim"
  if [[ ! -d "$NVIM_TARGET" ]]; then
    log_info "  Cloning Neovim config..."
    run "mkdir -p \"$(dirname "$NVIM_TARGET")\""
    git_clone_if_missing "https://github.com/pallandir/neovim.git" "$NVIM_TARGET"
  else
    log_skip "  Neovim config already exists"
  fi

  # Lazy sync
  log_info "  Syncing Neovim plugins..."
  run 'nvim --headless "+Lazy! sync" +qa 2>/dev/null || true'
}

install_rust() {
  echo ""
  echo -e "${BOLD}▶ rust${NC}"

  if command_exists rustc; then
    log_skip "  Rust already installed"
  else
    log_info "  Installing Rust via rustup..."
    run "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    run "source \"${HOME}/.cargo/env\""
  fi
}

install_tmux() {
  echo ""
  echo -e "${BOLD}▶ tmux${NC}"

  apt_install_if_missing tmux

  # TPM
  local TPM_DIR="${HOME}/.tmux/plugins/tpm"
  if [[ -d "$TPM_DIR" ]]; then
    log_skip "  TPM already installed"
  else
    log_info "  Installing TPM..."
    git_clone_if_missing "https://github.com/tmux-plugins/tpm" "$TPM_DIR"
  fi

  # tmux.conf symlink
  local TMUX_CONF_SRC="${SCRIPT_DIR}/../tmux/tmux.conf"
  if [[ -f "$TMUX_CONF_SRC" ]]; then
    log_info "  Linking tmux.conf..."
    ensure_symlink "$TMUX_CONF_SRC" "${HOME}/.tmux.conf"
  fi
}

install_opencode() {
  echo ""
  echo -e "${BOLD}▶ opencode${NC}"

  if command_exists opencode; then
    log_skip "  OpenCode already installed"
  else
    log_info "  Installing OpenCode..."
    run "curl -fsSL https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install | bash"
  fi

  local OPENCODE_INSTALL="${SCRIPT_DIR}/../opencode/install.sh"
  if [[ -f "$OPENCODE_INSTALL" ]]; then
    log_info "  Installing OpenCode configuration..."
    run "bash \"$OPENCODE_INSTALL\""
  fi
}

install_flatpak() {
  echo ""
  echo -e "${BOLD}▶ flatpak${NC}"

  if flatpak remotes 2>/dev/null | grep -q flathub; then
    log_skip "  Flathub already added"
  else
    log_info "  Adding Flathub repository..."
    run "sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
  fi
}

install_display-scaling() {
  echo ""
  echo -e "${BOLD}▶ display-scaling${NC}"

  local SCALING_SRC="${SCRIPT_DIR}/display-scaling.conf"
  local SCALING_DST="${HOME}/.config/environment.d/display-scaling.conf"

  if [[ -f "$SCALING_SRC" ]]; then
    log_info "  Linking display-scaling.conf..."
    ensure_symlink "$SCALING_SRC" "$SCALING_DST"
  else
    log_warn "  display-scaling.conf not found in dotfiles"
  fi
}

install_gtk-themes() {
  echo ""
  echo -e "${BOLD}▶ gtk-themes${NC}"

  local THEME_SRC="${SCRIPT_DIR}/../.themes"
  local GTK3_SRC="${SCRIPT_DIR}/../gtk-3.0"
  local GTK4_SRC="${SCRIPT_DIR}/../gtk-4.0"

  mkdir -p "${HOME}/.themes"
  mkdir -p "${HOME}/.config/gtk-3.0"
  mkdir -p "${HOME}/.config/gtk-4.0"

  if [[ -d "$THEME_SRC" ]]; then
    log_info "  Syncing .themes..."
    run "rsync -a \"$THEME_SRC/\" \"${HOME}/.themes/\""
  fi
  if [[ -d "$GTK3_SRC" ]]; then
    log_info "  Syncing gtk-3.0..."
    run "rsync -a \"$GTK3_SRC/\" \"${HOME}/.config/gtk-3.0/\""
  fi
  if [[ -d "$GTK4_SRC" ]]; then
    log_info "  Syncing gtk-4.0..."
    run "rsync -a \"$GTK4_SRC/\" \"${HOME}/.config/gtk-4.0/\""
  fi
}

#####################################
# Usage
#####################################

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --all       Install all components (skip menu)"
  echo "  --dry-run   Print commands without executing"
  echo "  --help      Show this help message"
  echo ""
  echo "Environment:"
  echo "  DRY_RUN=1   Same as --dry-run"
}

#####################################
# main
#####################################

main() {
  local skip_menu=0

  for arg in "$@"; do
    case "$arg" in
      --all)     skip_menu=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --help)    usage; exit 0 ;;
      *)         log_err "Unknown option: $arg"; usage; exit 1 ;;
    esac
  done

  if (( skip_menu )); then
    SELECTED=("${COMPONENTS[@]}")
  else
    show_menu
    read -r input
    parse_selection "$input"
  fi

  resolve_deps

  echo ""
  log_info "Components to install: ${SELECTED[*]}"
  if [[ "$DRY_RUN" == "1" ]]; then
    log_warn "[dry-run mode enabled]"
  fi

  for comp in "${SELECTED[@]}"; do
    "install_${comp}"
  done

  echo ""
  echo -e "${GREEN}${BOLD}Linux setup complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "  - Log out and log back in to apply shell and display scaling changes"
  echo "  - Open tmux and run 'prefix + I' to install plugins"
  echo "  - Open Neovim and wait for Mason to install LSPs/formatters"
  echo "  - Run :checkhealth in Neovim to verify everything is working"
}

main "$@"
