# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="jovial"

# Plugins
plugins=(
  git
  autojump
  urltools
  bgnotify
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-enquirer
  jovial
)

source $ZSH/oh-my-zsh.sh

# ===================
# Cross-platform paths
# ===================

# Homebrew (macOS)
if [[ -d "/opt/homebrew/bin" ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
  export HOMEBREW_NO_AUTO_UPDATE=true
fi

# Neovim (Linux custom path)
if [[ -d "/opt/nvim" ]]; then
  export PATH="$PATH:/opt/nvim/"
fi

# Go
if [[ -d "/usr/local/go/bin" ]]; then
  export PATH="$PATH:/usr/local/go/bin"
fi
if [[ -d "$HOME/go/bin" ]]; then
  export PATH="$PATH:$HOME/go/bin"
fi

# Rust
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Local bin
if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi

# ===================
# OpenCode environment
# ===================
if [[ -f "$HOME/.config/opencode/.env" ]]; then
  set -a && source "$HOME/.config/opencode/.env" && set +a
fi

# ===================
# Completions
# ===================
autoload -U +X bashcompinit && bashcompinit

# Tofu (if installed)
if command -v tofu &>/dev/null; then
  complete -o nospace -C "$(which tofu)" tofu
fi
