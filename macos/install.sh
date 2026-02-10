#!/bin/zsh

#####################################
# Globals
#####################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DRY_RUN=${DRY_RUN:-0}

#####################################
# Guards
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

git_ssh_auth_ok() {
  ssh -T git@github.com 2>&1 | grep -qi "successfully authenticated"
}

is_brew_pkg_installed() {
  brew list "$1" &>/dev/null
}

is_brew_cask_installed() {
  brew list --cask "$1" &>/dev/null
}

#####################################
# Tools definition
#####################################

toolsList='[
  {
    "tool": "brew",
    "install_command": "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
    "dependancy": "",
    "config_command": ""
  },
  {
    "tool": "iterm2",
    "install_command": "brew install --cask iterm2",
    "dependancy": "brew",
    "config_command": ""
  },
  {
    "tool": "zsh",
    "install_command": "sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"",
    "dependancy": "",
    "config_command": ""
  },
  {
    "tool": "nvim",
    "install_command": "brew install nvim",
    "dependancy": "brew",
    "config_command": "git clone https://github.com/pallandir/neovim.git ~/.config/nvim"
  },
  {
    "tool": "tmux",
    "install_command": "brew install tmux",
    "dependancy": "brew",
    "config_command": ""
  },
  {
    "tool": "aerospace",
    "install_command": "brew install --cask aerospace",
    "dependancy": "brew",
    "config_command": "mkdir -p ~/.config/aerospace && cp aerospace.toml ~/.config/aerospace"
  }
]'

#####################################
# Intro
#####################################

echo "\nInstalling configuration for macOS\n"
echo "Setup includes:"
echo " - Homebrew"
echo " - Iterm2"
echo " - ZSH (+ config)"
echo " - Neovim (+ config)"
echo " - Tmux (+ TPM + config)"
echo " - OpenCode AI"
echo " - Aerospace (+ config)"
echo

if git_ssh_auth_ok; then
  echo "${GREEN}GitHub auth [OK]${NC}"
else
  echo "${YELLOW}GitHub SSH auth not detected (some configs may fail).${NC}"
fi

#####################################
# Install + config loop (serial)
#####################################

while IFS= read -r item; do
  tool=$(jq -r '.tool' <<< "$item")
  install_command=$(jq -r '.install_command' <<< "$item")
  dependancy=$(jq -r '.dependancy' <<< "$item")
  config_command=$(jq -r '.config_command' <<< "$item")

  echo "\n▶ Processing $tool"

  # Dependency check
  if [[ -n "$dependancy" ]] && ! command -v "$dependancy" &>/dev/null; then
    echo "${RED}Dependency '$dependancy' required for $tool is missing. Aborting.${NC}"
    exit 1
  fi

  # Installation (idempotent)
  case "$install_command" in
    brew\ install\ --cask*)
      if is_brew_cask_installed "$tool"; then
        echo "$tool already installed (cask)"
      else
        echo "${GREEN}Installing $tool${NC}"
        run "$install_command"
      fi
      ;;
    brew\ install*)
      if is_brew_pkg_installed "$tool"; then
        echo "$tool already installed"
      else
        echo "${GREEN}Installing $tool${NC}"
        run "$install_command"
      fi
      ;;
    *)
      if command -v "$tool" &>/dev/null; then
        echo "$tool already installed"
      else
        echo "${GREEN}Installing $tool (script-based)${NC}"
        run "$install_command"
      fi
      ;;
  esac

  # Configuration step
  if [[ -n "$config_command" ]]; then
    echo "${GREEN}Configuring $tool${NC}"
    run "$config_command"
  fi

done < <(print -r -- "$toolsList" | jq -c '.[]')

#####################################
# Neovim Providers (Python, Node.js, Go)
#####################################
echo "\n▶ Installing Neovim providers"

# Node.js
if ! command -v node &>/dev/null; then
  echo "${GREEN}Installing Node.js...${NC}"
  run "brew install node"
else
  echo "Node.js $(node --version) already installed"
fi

# Neovim npm package
if ! npm list -g neovim &>/dev/null; then
  echo "${GREEN}Installing neovim npm package...${NC}"
  run "npm install -g neovim"
else
  echo "Neovim npm package already installed"
fi

# Python venv with pynvim
NVIM_VENV="${HOME}/.local/share/nvim/python-venv"
if [[ ! -d "$NVIM_VENV" ]]; then
  echo "${GREEN}Creating Neovim Python venv...${NC}"
  run "python3 -m venv $NVIM_VENV"
  run "$NVIM_VENV/bin/pip install --upgrade pip pynvim"
else
  echo "Neovim Python venv already exists"
fi

# Go (for gopls)
if ! command -v go &>/dev/null; then
  echo "${GREEN}Installing Go...${NC}"
  run "brew install go"
else
  echo "Go $(go version) already installed"
fi

#####################################
# ZSH Configuration
#####################################
echo "\n▶ Configuring ZSH"
ZSHRC_SRC="${SCRIPT_DIR}/../.zshrc"
if [[ -f "$ZSHRC_SRC" ]]; then
  echo "${GREEN}Linking .zshrc...${NC}"
  run "ln -sf $(realpath $ZSHRC_SRC) ${HOME}/.zshrc"
fi

# Install zsh plugins
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
  echo "${GREEN}Installing zsh-autosuggestions...${NC}"
  run "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
  echo "${GREEN}Installing zsh-syntax-highlighting...${NC}"
  run "git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# Install Jovial theme
if [[ ! -f "${ZSH_CUSTOM}/themes/jovial.zsh-theme" ]]; then
  echo "${GREEN}Installing Jovial theme...${NC}"
  run "git clone https://github.com/zthxxx/jovial ${ZSH_CUSTOM}/themes/jovial"
  run "cp ${ZSH_CUSTOM}/themes/jovial/jovial.zsh-theme ${ZSH_CUSTOM}/themes/"
fi

#####################################
# TPM + Tmux Config
#####################################
echo "\n▶ Configuring Tmux"
TPM_DIR="${HOME}/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo "${GREEN}Installing TPM...${NC}"
  run "git clone https://github.com/tmux-plugins/tpm $TPM_DIR"
else
  echo "TPM already installed"
fi

SCRIPT_DIR="${0:A:h}"
TMUX_CONF_SRC="${SCRIPT_DIR}/../tmux/tmux.conf"
if [[ -f "$TMUX_CONF_SRC" ]]; then
  echo "${GREEN}Linking tmux.conf...${NC}"
  run "ln -sf $(realpath $TMUX_CONF_SRC) ${HOME}/.tmux.conf"
fi

#####################################
# OpenCode AI
#####################################
echo "\n▶ Installing OpenCode"
if ! command -v opencode &>/dev/null; then
  run "brew install opencode-ai/tap/opencode"
else
  echo "OpenCode already installed"
fi

# Install OpenCode configuration
OPENCODE_INSTALL="${SCRIPT_DIR}/../opencode/install.sh"
if [[ -f "$OPENCODE_INSTALL" ]]; then
  echo "${GREEN}Installing OpenCode configuration...${NC}"
  run "bash $OPENCODE_INSTALL"
fi

#####################################
# Done
#####################################

echo "\n${GREEN}macOS setup complete 🎉${NC}"
