#!/bin/bash
set -e

# Kraken CLI Universal Installer (silent)
# Works on Linux, macOS, and Windows (Git Bash, WSL)
# Author: iammhador

# Detect OS
OS_TYPE=$(uname -s 2>/dev/null || echo "Windows")
case "$OS_TYPE" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="macOS";;
    *MINGW*|*CYGWIN*|*MSYS*|Windows*) OS="Windows";;
    *)          OS="Unknown";;
esac

# Set installation directory
if [[ "$OS" == "Windows" ]]; then
    INSTALL_DIR="$USERPROFILE\\.kraken-cli"
    PROFILE_FILE="$USERPROFILE\\kraken_path.cmd"
else
    INSTALL_DIR="$HOME/.kraken-cli"
    PROFILE_FILE="$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && PROFILE_FILE="$HOME/.zshrc"
fi

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

# Make binary executable (Linux/macOS)
if [[ "$OS" != "Windows" ]]; then
    chmod +x "$KRAKEN_BINARY"
fi

# Add to PATH
if [[ "$OS" == "Windows" ]]; then
    # Create a cmd wrapper to add to PATH
    WRAPPER="$INSTALL_DIR\\kraken.cmd"
    echo "@echo off" > "$WRAPPER"
    echo "\"$KRAKEN_BINARY\" %*" >> "$WRAPPER"

    # Add to user PATH permanently
    CURRENT_PATH=$(powershell -Command "[Environment]::GetEnvironmentVariable('PATH','User')")
    if [[ ":$CURRENT_PATH:" != *":$INSTALL_DIR:"* ]]; then
        powershell -Command "[Environment]::SetEnvironmentVariable('PATH', '$CURRENT_PATH;$INSTALL_DIR', 'User')"
    fi
else
    # Only append to profile if not already present
    if ! grep -q "$INSTALL_DIR" "$PROFILE_FILE"; then
        echo "" >> "$PROFILE_FILE"
        echo "# Kraken CLI" >> "$PROFILE_FILE"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$PROFILE_FILE"
    fi
    # Export for current session
    export PATH="$INSTALL_DIR:$PATH"
fi

# Success message
echo "✅ Kraken CLI installed successfully!"
echo "Run 'kraken --help' to see available commands."
if [[ "$OS" == "Windows" ]]; then
    echo "⚠️  Please restart your terminal (CMD, PowerShell, Git Bash) for PATH changes to take effect."
fi
