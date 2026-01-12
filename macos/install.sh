#!/bin/zsh

## Global

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)

function check_command_exec(){
    local toolName="$1"
    if [ $? -eq 0 ];
    then
        echo "${GREEN}${toolName} status: [OK] ${NC}"
    else
        echo "${RED}Tool installation failed aborting setup.${NC}"
        exit 0
    fi
}

function is_tool_installed(){
    local toolName="$1"

    if command -v "$toolName" &> /dev/null; then
        echo "${RED}${toolName} is already installed.Skipping...${NC}"
        return 0
    else
        return 1
    fi
}

function log_tool_install(){
    local toolName="$1"
    echo "${GREEN}Installing ${toolName}...${NC}"
}

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
    
    if [  "$dependancy" -ne "" ]; then
        if ! command -v "$dependancy"; then
            echo "${RED}Dependancy: $dependancy to install tool $tool not installed. Aborting setup...${NC}"
        fi
    fi
    echo "${GREEN}Installing $tool${NC}"
    if ! command -v "$tool"; then
        eval "$install_command"
    fi
done
exit 0

