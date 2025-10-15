#!/bin/bash
set -e

# ────────────────────────────────
# Kraken CLI Cross-Platform Installer
# Works on Linux, macOS, Windows (PowerShell, CMD, Git Bash)
# ────────────────────────────────

INSTALL_DIR="$HOME/.kraken-cli"
KRAKEN_BINARY="$INSTALL_DIR/kraken"
GITHUB_RAW_URL="https://raw.githubusercontent.com/iammhador/kraken-cli/main/kraken"

echo "🦑 Installing Kraken CLI..."

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download binary
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GITHUB_RAW_URL" -o "$KRAKEN_BINARY"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$GITHUB_RAW_URL" -O "$KRAKEN_BINARY"
else
    echo "❌ Neither curl nor wget found. Cannot download Kraken CLI."
    exit 1
fi

# Make executable (Unix only)
if [ "$(uname -s | grep -iE 'linux|darwin')" ]; then
    chmod +x "$KRAKEN_BINARY"
fi

# ────────── Configure PATH ──────────
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')

if [[ "$OS_TYPE" == *"linux"* ]] || [[ "$OS_TYPE" == *"darwin"* ]]; then
    # Detect shell profile
    PROFILE_FILE="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; fi
    if ! grep -q "$INSTALL_DIR" "$PROFILE_FILE"; then
        echo "" >> "$PROFILE_FILE"
        echo "# Kraken CLI" >> "$PROFILE_FILE"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$PROFILE_FILE"
    fi
    export PATH="$INSTALL_DIR:$PATH"

elif [[ "$OS_TYPE" == *"mingw"* ]] || [[ "$OS_TYPE" == *"cygwin"* ]] || [[ "$OS_TYPE" == *"msys"* ]]; then
    # Windows (Git Bash, MSYS, Cygwin)
    export PATH="$INSTALL_DIR:$PATH"
    if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
        echo "Adding Kraken to Windows user PATH..."
        powershell.exe -NoProfile -Command "[Environment]::SetEnvironmentVariable('PATH', '\$env:USERPROFILE\\.kraken-cli;' + [Environment]::GetEnvironmentVariable('PATH','User'), 'User')"
    fi
fi

# ────────── Finished ──────────
echo "✅ Kraken CLI installed successfully!"
echo "Run 'kraken --help' to see available commands."
echo ""
echo "Note: On Windows CMD/PowerShell, restart your terminal to apply PATH changes."
