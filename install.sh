#!/bin/bash
set -e

# Kraken CLI Installer (silent)
INSTALL_DIR="$HOME/.kraken-cli"
KRAKEN_BINARY="$INSTALL_DIR/kraken"
GITHUB_RAW_URL="https://raw.githubusercontent.com/iammhador/kraken-cli/main/kraken"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download Kraken binary
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GITHUB_RAW_URL" -o "$KRAKEN_BINARY"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$GITHUB_RAW_URL" -O "$KRAKEN_BINARY"
else
    echo "❌ Neither curl nor wget found. Cannot download Kraken CLI."
    exit 1
fi

# Make binary executable
chmod +x "$KRAKEN_BINARY"

# Add to PATH in shell profile (bash, zsh, fallback)
PROFILE_FILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; fi

# Only append if not already in PATH
if ! grep -q "$INSTALL_DIR" "$PROFILE_FILE"; then
    echo "" >> "$PROFILE_FILE"
    echo "# Kraken CLI" >> "$PROFILE_FILE"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$PROFILE_FILE"
fi

# Export for current session
export PATH="$INSTALL_DIR:$PATH"

# Done
echo "✅ Kraken CLI installed successfully!"
echo "Run 'kraken --help' to see available commands."
