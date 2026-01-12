#!/bin/zsh
set -euo pipefail

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
    "config_command": "git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh"
  },
  {
    "tool": "nvim",
    "install_command": "brew install nvim",
    "dependancy": "brew",
    "config_command": "git clone https://github.com/youruser/nvim-config.git ~/.config/nvim"
  },
  {
    "tool": "tmux",
    "install_command": "brew install tmux",
    "dependancy": "brew",
    "config_command": "git clone https://github.com/youruser/tmux-config.git ~/.config/tmux"
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
echo " - Tmux (+ config)"
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
# Done
#####################################

echo "\n${GREEN}macOS setup complete 🎉${NC}"
