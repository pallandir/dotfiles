#!/bin/zsh

## Global

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)

function check_command_exec(){
    local toolName="$1"
    if [ $? -eq 0 ];
    then
        echo "${GREEN} ${toolName} status: [OK] ${NC}"
    else
        echo "${RED}Tool installation failed aborting setup.${NC}"
        exit 0
    fi
}

function is_tool_installed(){
    local toolName="$1"

    if command -v "$toolName" &> /dev/null; then
        echo "${RED}${toolName} is already installed. Skipping...${NC}"
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

## Prerequisites

echo "\n${GREEN}Installing configuration for macOS${NC}\n"
echo "${GREEN}Setup includes: \n - Homebrew \n - Iterm2 \n - ZSH (+ config) \n - Neovim (+ config) \n - Tmux \n - Aerospace tiling manager${NC}"
if ! git_ssh_auth_ok; then
    echo "\n${RED}You need a valid GitHub SSH key in order to clone configurations.\nFind more information here: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent.${NC}"
else
    echo "GitHub auth [OK]"
fi
exit 0

## Install and setup Homebrew


TOOL="brew"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    check_command_exec "$TOOL"
fi


## Install and config iterm2

TOOL="iterm2"
log_tool_install "$TOOL"
if is_tool_installed "brew"; then
    brew install --cask iterm2
    check_command_exec "$TOOL"
fi

## Install and setup oh-my-zsh

TOOL="zsh"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "${GREEN}Installing Jovial theme for zsh...${NC}"
    curl -sSL https://github.com/zthxxx/jovial/raw/master/installer.sh | sudo -E bash -s ${USER:=`whoami`}
    check_command_exec "$TOOL"
fi


## Install and config Neovim

TOOL="nvim"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    brew install neovim
    echo "${GREEN}Cloning nvim config into ~/.config/nvim${NC}"
    git clone git@github.com:pallandir/neovim.git ~/.config/nvim
    check_command_exec "$TOOL"
fi

## Install and setup tmux

TOOL="tmux"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    brew install tmux
    check_command_exec "$TOOL"
fi

## Install and setup aerospace

TOOL="aerospace"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    brew install --cask aerospace
    mkdir -p ~/.config/aerospace
    cp aerospace.toml ~/.config/aerospace/
    check_command_exec "$TOOL"
fi
