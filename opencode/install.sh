#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

echo "Installing opencode configuration..."

# Create config directory
mkdir -p "$CONFIG_DIR"

# Symlink main config
ln -sf "$SCRIPT_DIR/opencode.json" "$CONFIG_DIR/opencode.json"
echo "  Linked: opencode.json"

# Symlink agents directory
if [ -L "$CONFIG_DIR/agents" ]; then
    rm "$CONFIG_DIR/agents"
elif [ -d "$CONFIG_DIR/agents" ]; then
    echo "  Warning: $CONFIG_DIR/agents exists as directory, backing up..."
    mv "$CONFIG_DIR/agents" "$CONFIG_DIR/agents.backup.$(date +%s)"
fi
ln -sf "$SCRIPT_DIR/agents" "$CONFIG_DIR/agents"
echo "  Linked: agents/"

# Copy .env.example if .env doesn't exist
if [ ! -f "$CONFIG_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env.example" "$CONFIG_DIR/.env"
    echo "  Created: .env (edit with your credentials)"
else
    echo "  Skipped: .env (already exists)"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit $CONFIG_DIR/.env with your credentials"
echo "  2. Add to your shell profile:"
echo "     set -a && source $CONFIG_DIR/.env && set +a"
echo ""
echo "Or run: source $CONFIG_DIR/.env && opencode"
