
#!/bin/bash

# Kraken CLI Installer
# Universal installer for Linux/macOS supporting all shells

set -e

echo "🦑 Installing Kraken CLI..."

# Configuration
INSTALL_DIR="$HOME/.kraken-cli"
KRAKEN_BINARY="$INSTALL_DIR/kraken"
GITHUB_RAW_URL="https://raw.githubusercontent.com/iammhador/kraken-cli/main/kraken"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Check if running on supported OS
check_os() {
  case "$(uname -s)" in
    Linux*)
      OS="Linux"
      print_info "Detected OS: Linux"
      ;;
    Darwin*)
      OS="macOS"
      print_info "Detected OS: macOS"
      ;;
    *)
      print_error "Unsupported operating system: $(uname -s)"
      print_info "Kraken CLI currently supports Linux and macOS only."
      exit 1
      ;;
  esac
}

# Check if required commands are available
check_dependencies() {
  local missing_deps=()
  
  # Check for curl or wget
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    missing_deps+=("curl or wget")
  fi
  
  # Check for jq
  if ! command -v jq >/dev/null 2>&1; then
    print_warning "jq is not installed. It's required for Kraken CLI to work."
    missing_deps+=("jq")
  fi
  
  # Check for vagrant
  if ! command -v vagrant >/dev/null 2>&1; then
    print_warning "Vagrant is not installed. It's required for Kraken CLI to work."
    missing_deps+=("vagrant")
  fi
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    print_warning "Missing dependencies: ${missing_deps[*]}"
    echo ""
    print_info "Please install the missing dependencies:"
    
    if [[ "$OS" == "Linux" ]]; then
      echo ""
      echo "For Fedora/RHEL:"
      echo "  sudo dnf install -y jq vagrant vagrant-libvirt @virtualization"
      echo ""
      echo "For Ubuntu/Debian:"
      echo "  sudo apt update"
      echo "  sudo apt install -y jq vagrant"
      echo ""
      echo "For Arch Linux:"
      echo "  sudo pacman -S jq vagrant"
    elif [[ "$OS" == "macOS" ]]; then
      echo ""
      echo "For macOS (using Homebrew):"
      echo "  brew install jq vagrant"
    fi
    
    echo ""
    read -p "Continue installation anyway? [y/N]: " continue_install
    if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
}

# Create installation directory
create_install_dir() {
  if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
    print_error "Failed to create install directory: $INSTALL_DIR"
    print_info "Try running with sudo:"
    echo "  curl -fsSL https://raw.githubusercontent.com/iammhador/kraken-cli/main/install.sh | sudo bash"
    exit 1
  fi
  print_success "Created installation directory: $INSTALL_DIR"
}

# Download Kraken binary
download_kraken() {
  print_info "Downloading Kraken CLI from GitHub..."
  
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL "$GITHUB_RAW_URL" -o "$KRAKEN_BINARY"; then
      print_success "Downloaded Kraken CLI successfully"
    else
      print_error "Failed to download Kraken CLI"
      exit 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q "$GITHUB_RAW_URL" -O "$KRAKEN_BINARY"; then
      print_success "Downloaded Kraken CLI successfully"
    else
      print_error "Failed to download Kraken CLI"
      exit 1
    fi
  else
    print_error "Neither curl nor wget found. Please install one of them."
    exit 1
  fi
}

# Make binary executable
make_executable() {
  chmod +x "$KRAKEN_BINARY"
  print_success "Made Kraken CLI executable"
}

# Detect current shell and determine profile file
detect_shell_profile() {
  local current_shell
  local profile_files=()
  
  # Get current shell (remove path, keep only shell name)
  current_shell=$(basename "$SHELL" 2>/dev/null || echo "bash")
  
  case "$current_shell" in
    bash)
      profile_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
      ;;
    zsh)
      profile_files=("$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.profile")
      ;;
    fish)
      profile_files=("$HOME/.config/fish/config.fish")
      # Create fish config directory if it doesn't exist
      mkdir -p "$HOME/.config/fish" 2>/dev/null
      ;;
    ksh|mksh)
      profile_files=("$HOME/.kshrc" "$HOME/.profile")
      ;;
    tcsh|csh)
      profile_files=("$HOME/.tcshrc" "$HOME/.cshrc")
      ;;
    dash)
      profile_files=("$HOME/.profile")
      ;;
    *)
      # Fallback: try common profile files
      profile_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
      print_warning "Unknown shell: $current_shell. Trying common profile files..."
      ;;
  esac
  
  # Find the first existing profile file, or create the primary one
  for profile in "${profile_files[@]}"; do
    if [[ -f "$profile" ]]; then
      echo "$profile"
      return 0
    fi
  done
  
  # If no profile file exists, create the primary one
  touch "${profile_files[0]}"
  echo "${profile_files[0]}"
}

# Function to add PATH export based on shell type
add_to_path() {
  local profile_file="$1"
  local path_export_line
  
  # Determine the correct syntax based on shell
  local shell_name=$(basename "$SHELL" 2>/dev/null || echo "bash")
  
  case "$shell_name" in
    fish)
      # Fish shell uses different syntax
      path_export_line='set -gx PATH "$HOME/.kraken-cli" $PATH'
      ;;
    tcsh|csh)
      # C shell family uses setenv
      path_export_line='setenv PATH "$HOME/.kraken-cli:$PATH"'
      ;;
    *)
      # POSIX-compatible shells (bash, zsh, dash, ksh, etc.)
      path_export_line='export PATH="$HOME/.kraken-cli:$PATH"'
      ;;
  esac
  
  # Check if PATH is already configured
  if [[ -f "$profile_file" ]] && grep -q "$HOME/.kraken-cli" "$profile_file" 2>/dev/null; then
    print_info "PATH already configured in $profile_file"
    return 0
  fi
  
  # Add the export line
  echo "" >> "$profile_file"
  echo "# Kraken CLI" >> "$profile_file"
  echo "$path_export_line" >> "$profile_file"
  print_success "Updated $profile_file with Kraken CLI path"
  
  # For fish shell, also update the current session differently
  if [[ "$shell_name" == "fish" ]]; then
    print_info "Fish shell detected. Please restart your terminal or run: source ~/.config/fish/config.fish"
  fi
}

# Configure PATH in shell profile
configure_path() {
  PROFILE_FILE=$(detect_shell_profile)
  
  if [[ -n "$PROFILE_FILE" ]]; then
    add_to_path "$PROFILE_FILE"
  else
    print_warning "Could not determine appropriate profile file."
    print_info "Please manually add this line to your shell's profile file:"
    echo "  export PATH=\"\$HOME/.kraken-cli:\$PATH\""
  fi
  
  # Apply to current session (works for POSIX-compatible shells)
  export PATH="$HOME/.kraken-cli:$PATH"
}

# Display post-installation instructions
show_instructions() {
  local shell_name=$(basename "$SHELL" 2>/dev/null || echo "bash")
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print_success "Kraken CLI installed successfully! 🦑"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Check if command is immediately available
  if command -v kraken >/dev/null 2>&1; then
    print_success "Kraken is ready to use!"
    echo ""
    echo "Get started:"
    echo "  kraken init      # Launch a new VM"
    echo "  kraken --help    # Show all commands"
  else
    print_info "To use Kraken, restart your terminal or run:"
    echo ""
    
    case "$shell_name" in
      fish)
        echo "  source ~/.config/fish/config.fish"
        ;;
      tcsh|csh)
        echo "  source $PROFILE_FILE"
        ;;
      *)
        echo "  source $PROFILE_FILE"
        ;;
    esac
    
    echo ""
    echo "Then run:"
    echo "  kraken init      # Launch a new VM"
    echo "  kraken --help    # Show all commands"
  fi
  
  echo ""
  print_info "Before using Kraken, ensure you have:"
  echo "  • libvirt/KVM or VirtualBox installed"
  echo "  • Vagrant installed"
  echo "  • jq installed"
  echo ""
  
  if [[ "$OS" == "Linux" ]]; then
    echo "Quick setup for Fedora/RHEL:"
    echo "  sudo dnf install -y @virtualization vagrant vagrant-libvirt jq"
    echo "  sudo systemctl start libvirtd && sudo systemctl enable libvirtd"
    echo "  sudo virsh net-start default && sudo virsh net-autostart default"
    echo ""
  elif [[ "$OS" == "macOS" ]]; then
    echo "Quick setup for macOS:"
    echo "  brew install vagrant jq"
    echo ""
  fi
  
  print_info "Documentation: https://github.com/iammhador/kraken-cli"
  echo ""
}

# Main installation flow
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🦑 Kraken CLI Installer"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  check_os
  check_dependencies
  create_install_dir
  download_kraken
  make_executable
  configure_path
  show_instructions
}

# Run main installation
main
