#!/bin/bash
# setup-cloud-mac.sh — Run this on your Scaleway Mac mini after first boot
# Usage: ssh <mac-ip> 'bash -s' < setup-cloud-mac.sh

set -euo pipefail

echo "=== Privlens Cloud Mac Setup ==="

# Accept Xcode license (Xcode must already be installed from App Store)
echo "Accepting Xcode license..."
sudo xcodebuild -license accept 2>/dev/null || echo "Install Xcode from App Store first!"

# Install Xcode CLI tools
echo "Installing Xcode CLI tools..."
xcode-select --install 2>/dev/null || echo "CLI tools already installed"

# Install Homebrew
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install dev tools
echo "Installing dev tools..."
brew install --quiet swiftlint swiftformat gh

# Configure git
echo "Configuring git..."
git config --global user.name "Peter Kim"
git config --global user.email "peterkim676@gmail.com"

# Clone the repo
echo "Cloning Privlens repo..."
mkdir -p ~/Developer
if [ ! -d ~/Developer/privlens ]; then
    git clone https://github.com/peterkimpro/privlens.git ~/Developer/privlens
else
    echo "Repo already cloned"
fi

# Enable SSH (reminder)
echo ""
echo "=== MANUAL STEPS ==="
echo "1. System Settings → General → Sharing → Remote Login → ON"
echo "2. From your Linux VDI: ssh-copy-id $(whoami)@$(hostname)"
echo "3. Install Xcode from App Store if not done"
echo ""
echo "=== Setup Complete ==="
echo "Connect from VS Code: code --remote ssh-remote+privlens-mac ~/Developer/privlens"
