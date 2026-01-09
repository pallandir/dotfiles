#!/bin/zsh

## Preset

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)

function is_homebrew_installed() {
    if command -v brew &> /dev/null; then
        return 0
    else
        return 1
    fi
}

function check_command_exec(){
    if [ $? -eq 0 ];
    then
        echo "${GREEN}Tool installed successfully${NC}"
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


## Install and setup Homebrew

TOOL="brew"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    check_command_exec
fi


## Install and config iterm2

TOOL="iterm2"
log_tool_install "$TOOL"
if is_tool_installed "brew"; then
    brew install --cask iterm2
    check_command_exec
fi

## Install and setup oh-my-zsh

TOOL="zsh"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    check_command_exec
fi


## Install and config Neovim

TOOL="nvim"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    brew install neovim
    check_command_exec
    echo "${GREEN}Cloning nvim config into ~/.config/nvim"
    git clone git@github.com:pallandir/neovim.git ~/.config/nvim
fi

## Install and setup tmux

## Install and setup aerospace

TOOL="aerospace"
log_tool_install "$TOOL"
if ! is_tool_installed "$TOOL"; then
    brew install --cask aerospace
    mkdir -p ~/.config/aerospace
    cp aerospace.toml ~/.config/aerospace/
    check_command_exec
fi
