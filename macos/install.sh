#!/bin/zsh

## Global

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)


function git_ssh_auth_ok() {
  ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"
}

toolsList='[{"tool": "brew", "install_command":"/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"", "dependancy":""},{"tool":"iterm2", "install_command":"brew install --cask iterm2","dependancy":"brew"},{"tool":"zsh","install_command":"sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"","dependancy":""},{"tool":"nvim","install_command":"brew install nvim", "dependancy":"brew"}, {"tool":"tmux", "install_command":"brew install tmux", "dependancy":"brew"},{"tool":"aerospace","install_command":"brew install --cask aerospace","dependancy":"brew"}]'


## Prerequisites

echo "\nInstalling configuration for macOS\n"
echo "Setup includes: \n - Homebrew \n - Iterm2 \n - ZSH (+ config) \n - Neovim (+ config) \n - Tmux \n - Aerospace tiling manager"
if ! git_ssh_auth_ok; then
    echo "\n${RED}You need a valid GitHub SSH key in order to clone configurations.\nFind more information here: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent.${NC}"
else
    echo "${GREEN}GitHub auth [OK]${NC}"
fi

## Install and setup Homebrew

print -r -- "$toolsList" |
jq -c '.[]' |
while IFS= read -r item; do
    tool=$(jq -r '.tool' <<< "$item")
    install_command=$(jq -r '.install_command' <<< "$item")
    dependancy=$(jq -r '.dependancy' <<< "$item")
    
    echo "$install_command"
    if [ -n  "$dependancy" ]; then
        if ! command -v "$dependancy"; then
            echo "${RED}Dependancy: $dependancy to install tool $tool not installed. Aborting setup...${NC}"
        fi
    fi
    if  ! command -v "$tool" &> /dev/null; then
        echo "${GREEN}Installing $tool${NC}"
        eval "$install_command"
    fi
done
exit 0

