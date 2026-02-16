#!/bin/zsh

#####################################
# Globals
#####################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="${0:A:h}"
DRY_RUN=${DRY_RUN:-0}

#####################################
# Platform guard
#####################################

if [[ "$(uname)" != "Darwin" ]]; then
  echo "${RED}This script is macOS-only.${NC}"
  exit 1
fi

#####################################
# Helpers
#####################################

run() {
  if (( DRY_RUN )); then
    echo "${YELLOW}[dry-run] $*${NC}"
  else
    eval "$@"
  fi
}

log_info()  { echo "${GREEN}$*${NC}" }
log_warn()  { echo "${YELLOW}$*${NC}" }
log_err()   { echo "${RED}$*${NC}" }
log_skip()  { echo "$*" }

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

is_brew_pkg_installed() { brew list "$1" &>/dev/null }
is_brew_cask_installed() { brew list --cask "$1" &>/dev/null }

#####################################
# Component definitions
#####################################

COMPONENTS=(brew iterm2 zsh nvim tmux opencode aerospace)

typeset -A COMP_DESC COMP_DEPS
COMP_DESC=(
  [brew]="Homebrew package manager"
  [iterm2]="iTerm2 terminal"
  [zsh]="Oh My Zsh + plugins + Jovial theme"
  [nvim]="Neovim + CLI tools + providers + config"
  [tmux]="Tmux + TPM + config"
  [opencode]="OpenCode AI + config"
  [aerospace]="Aerospace WM + config"
)
COMP_DEPS=(
  [brew]=""
  [iterm2]="brew"
  [zsh]=""
  [nvim]="brew"
  [tmux]="brew"
  [opencode]="brew"
  [aerospace]="brew"
)

#####################################
# Menu + selection + dependency resolution
#####################################

show_menu() {
  echo ""
  echo "${BOLD}==========================================="
  echo "  Dotfiles Installer - macOS"
  echo "===========================================${NC}"
  echo ""
  echo "Available components:"
  local i=1
  for comp in $COMPONENTS; do
    local dep_info=""
    if [[ -n "${COMP_DEPS[$comp]}" ]]; then
      dep_info=" ${BLUE}[requires: ${COMP_DEPS[$comp]}]${NC}"
    fi
    printf "  %d) %-12s %s%s\n" "$i" "$comp" "${COMP_DESC[$comp]}" "$dep_info"
    ((i++))
  done
  echo ""
  echo "  a) all        Install everything"
  echo ""
  printf "Select components (space/comma-separated, e.g. 1,3,4 or 'a' for all):\n> "
}

parse_selection() {
  local input="$1"

  if [[ -z "$input" || "$input" == "a" || "$input" == "all" ]]; then
    SELECTED=($COMPONENTS)
    return
  fi

  SELECTED=()
  local items=(${(s:,:)input//[ ]/ })
  for item in $items; do
    item="${item// /}"
    [[ -z "$item" ]] && continue
    if [[ "$item" =~ ^[0-9]+$ ]]; then
      if (( item >= 1 && item <= ${#COMPONENTS} )); then
        SELECTED+=("${COMPONENTS[$item]}")
      else
        log_err "Invalid number: $item"
        exit 1
      fi
    else
      local found=0
      for comp in $COMPONENTS; do
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
  for comp in $SELECTED; do
    local dep="${COMP_DEPS[$comp]}"
    if [[ -n "$dep" ]]; then
      local dep_found=0
      for s in $SELECTED $resolved; do
        [[ "$s" == "$dep" ]] && { dep_found=1; break }
      done
      if (( !dep_found )); then
        log_warn "Auto-adding '$dep' (required by $comp)"
        resolved+=("$dep")
      fi
    fi
  done
  SELECTED=($resolved $SELECTED)

  # Deduplicate and reorder according to COMPONENTS
  local ordered=()
  for comp in $COMPONENTS; do
    for s in $SELECTED; do
      if [[ "$s" == "$comp" ]]; then
        ordered+=("$comp")
        break
      fi
    done
  done
  SELECTED=($ordered)
}

#####################################
# install_* functions
#####################################

install_brew() {
  echo "\n${BOLD}▶ brew${NC}"
  if command -v brew &>/dev/null; then
    log_skip "  Homebrew already installed"
  else
    log_info "  Installing Homebrew..."
    run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  fi
}

install_iterm2() {
  echo "\n${BOLD}▶ iterm2${NC}"
  if is_brew_cask_installed iterm2; then
    log_skip "  iTerm2 already installed"
  else
    log_info "  Installing iTerm2..."
    run "brew install --cask iterm2"
  fi
}

install_zsh() {
  echo "\n${BOLD}▶ zsh${NC}"

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
}

install_nvim() {
  echo "\n${BOLD}▶ nvim${NC}"

  # Neovim
  if is_brew_pkg_installed neovim; then
    log_skip "  Neovim already installed"
  else
    log_info "  Installing Neovim..."
    run "brew install neovim"
  fi

  # CLI tools
  for tool in ripgrep fd fzf; do
    if is_brew_pkg_installed "$tool"; then
      log_skip "  $tool already installed"
    else
      log_info "  Installing $tool..."
      run "brew install $tool"
    fi
  done

  # Node.js
  if command -v node &>/dev/null; then
    log_skip "  Node.js already installed"
  else
    log_info "  Installing Node.js..."
    run "brew install node"
  fi

  # neovim npm package
  if npm list -g neovim &>/dev/null; then
    log_skip "  neovim npm package already installed"
  else
    log_info "  Installing neovim npm package..."
    run "npm install -g neovim"
  fi

  # tree-sitter-cli
  if command -v tree-sitter &>/dev/null; then
    log_skip "  tree-sitter-cli already installed"
  else
    log_info "  Installing tree-sitter-cli..."
    run "npm install -g tree-sitter-cli"
  fi

  # Python venv with pynvim
  local NVIM_VENV="${HOME}/.local/share/nvim/python-venv"
  if [[ -d "$NVIM_VENV" ]]; then
    log_skip "  Neovim Python venv already exists"
  else
    log_info "  Creating Neovim Python venv..."
    run "python3 -m venv $NVIM_VENV"
    run "$NVIM_VENV/bin/pip install --upgrade pip pynvim"
  fi

  # Go
  if command -v go &>/dev/null; then
    log_skip "  Go already installed"
  else
    log_info "  Installing Go..."
    run "brew install go"
  fi

  # Neovim config
  local NVIM_TARGET="${HOME}/.config/nvim"
  if [[ ! -d "$NVIM_TARGET" ]]; then
    log_info "  Cloning Neovim config..."
    run "mkdir -p \"$(dirname \"$NVIM_TARGET\")\""
    git_clone_if_missing "https://github.com/pallandir/neovim.git" "$NVIM_TARGET"
  else
    log_skip "  Neovim config already exists"
  fi
}

install_tmux() {
  echo "\n${BOLD}▶ tmux${NC}"

  if is_brew_pkg_installed tmux; then
    log_skip "  Tmux already installed"
  else
    log_info "  Installing Tmux..."
    run "brew install tmux"
  fi

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
  echo "\n${BOLD}▶ opencode${NC}"

  if command -v opencode &>/dev/null; then
    log_skip "  OpenCode already installed"
  else
    log_info "  Installing OpenCode..."
    run "brew install opencode-ai/tap/opencode"
  fi

  local OPENCODE_INSTALL="${SCRIPT_DIR}/../opencode/install.sh"
  if [[ -f "$OPENCODE_INSTALL" ]]; then
    log_info "  Installing OpenCode configuration..."
    run "bash \"$OPENCODE_INSTALL\""
  fi
}

install_aerospace() {
  echo "\n${BOLD}▶ aerospace${NC}"

  if is_brew_cask_installed aerospace; then
    log_skip "  Aerospace already installed"
  else
    log_info "  Installing Aerospace..."
    run "brew install --cask aerospace"
  fi

  local AERO_SRC="${SCRIPT_DIR}/aerospace.toml"
  if [[ -f "$AERO_SRC" ]]; then
    log_info "  Linking aerospace.toml..."
    ensure_symlink "$AERO_SRC" "${HOME}/.config/aerospace/aerospace.toml"
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
    SELECTED=($COMPONENTS)
  else
    show_menu
    read input
    parse_selection "$input"
  fi

  resolve_deps

  echo ""
  log_info "Components to install: ${SELECTED[*]}"
  if (( DRY_RUN )); then
    log_warn "[dry-run mode enabled]"
  fi

  for comp in $SELECTED; do
    install_${comp}
  done

  echo "\n${GREEN}${BOLD}macOS setup complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "  - Open tmux and run 'prefix + I' to install plugins"
  echo "  - Open Neovim and wait for Mason to install LSPs/formatters"
  echo "  - Run :checkhealth in Neovim to verify everything is working"
}

main "$@"
