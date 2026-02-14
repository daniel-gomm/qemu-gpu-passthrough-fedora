#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

GITHUB_REPO="daniel-gomm/qemu-gpu-passthrough-fedora"
GITHUB_BRANCH="${INSTALL_BRANCH:-main}"
SCRIPT_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/gpu_passthrough_update.bash"
COMMAND_NAME="gpu-passthrough"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/gpu-passthrough"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}GPU Passthrough Script Installer${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Create installation and config directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# Download script from GitHub
echo -e "${GREEN}Downloading script from GitHub...${NC}"
if command -v curl &> /dev/null; then
    curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$COMMAND_NAME"
elif command -v wget &> /dev/null; then
    wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/$COMMAND_NAME"
else
    echo -e "${RED}Error: Neither curl nor wget found. Please install one of them.${NC}"
    exit 1
fi

chmod +x "$INSTALL_DIR/$COMMAND_NAME"

# Configure all detected shells
SHELLS_CONFIGURED=0

# Configure bash
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "$INSTALL_DIR" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "${GREEN}Configuring bash${NC}"
        echo "" >> "$HOME/.bashrc"
        echo "# Added by GPU Passthrough installer" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
        echo "alias $COMMAND_NAME='$INSTALL_DIR/$COMMAND_NAME'" >> "$HOME/.bashrc"
        SHELLS_CONFIGURED=$((SHELLS_CONFIGURED + 1))
    fi
fi

# Configure zsh
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "$INSTALL_DIR" "$HOME/.zshrc" 2>/dev/null; then
        echo -e "${GREEN}Configuring zsh${NC}"
        echo "" >> "$HOME/.zshrc"
        echo "# Added by GPU Passthrough installer" >> "$HOME/.zshrc"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.zshrc"
        echo "alias $COMMAND_NAME='$INSTALL_DIR/$COMMAND_NAME'" >> "$HOME/.zshrc"
        SHELLS_CONFIGURED=$((SHELLS_CONFIGURED + 1))
    fi
fi

# Configure fish
if [ -f "$HOME/.config/fish/config.fish" ]; then
    if ! grep -q "$INSTALL_DIR" "$HOME/.config/fish/config.fish" 2>/dev/null; then
        echo -e "${GREEN}Configuring fish${NC}"
        echo "" >> "$HOME/.config/fish/config.fish"
        echo "# Added by GPU Passthrough installer" >> "$HOME/.config/fish/config.fish"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.config/fish/config.fish"
        FISH_FUNCTIONS_DIR="$HOME/.config/fish/functions"
        mkdir -p "$FISH_FUNCTIONS_DIR"
        echo "function $COMMAND_NAME" > "$FISH_FUNCTIONS_DIR/$COMMAND_NAME.fish"
        echo "    $INSTALL_DIR/$COMMAND_NAME \$argv" >> "$FISH_FUNCTIONS_DIR/$COMMAND_NAME.fish"
        echo "end" >> "$FISH_FUNCTIONS_DIR/$COMMAND_NAME.fish"
        SHELLS_CONFIGURED=$((SHELLS_CONFIGURED + 1))
    fi
fi

if [ $SHELLS_CONFIGURED -gt 0 ]; then
    echo -e "Installation completed! To use the script, restart your terminal or reload your shell config:"
    [ -f "$HOME/.bashrc" ] && echo -e "  ${CYAN}source ~/.bashrc${NC}"
    [ -f "$HOME/.zshrc" ] && echo -e "  ${CYAN}source ~/.zshrc${NC}"
    [ -f "$HOME/.config/fish/config.fish" ] && echo -e "  ${CYAN}source ~/.config/fish/config.fish${NC}"
    echo ""
    echo -e "Then run: ${GREEN}$COMMAND_NAME${NC}"
else
    echo -e "${RED}Warning: Found no compatible shell configuration files.${NC}"
    echo -e "You can run the script directly: ${GREEN}$INSTALL_DIR/$COMMAND_NAME${NC}"
fi
