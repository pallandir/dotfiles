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


## Install and setup Homebrew

echo "${GREEN}Installing Homebrew...${NC}"
TOOL="brew"

if ! is_tool_installed "$TOOL"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

check_command_exec

## Install and config iterm2

if is_homebrew_installed; then
    brew install --cask iterm2
else
    echo "${RED}❌ Homebrew is not installed aborting operation.${NC}"
fi

## Install and setup oh-my-zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

check_command_exec

## Install and config Neovim

## Install and setup tmux

## Install and setup aerospace
