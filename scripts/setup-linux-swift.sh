#!/bin/bash
# setup-linux-swift.sh — Install Swift toolchain on your Linux VDI
# This lets you build/test non-UI Swift code locally (no Mac needed)
# Usage: bash scripts/setup-linux-swift.sh

set -euo pipefail

SWIFT_VERSION="6.1"
SWIFT_RELEASE="swift-${SWIFT_VERSION}-RELEASE"
PLATFORM="ubuntu24.04"
INSTALL_DIR="/opt/swift"

echo "=== Installing Swift ${SWIFT_VERSION} on Linux ==="

# Check if already installed
if command -v swift &>/dev/null; then
    CURRENT=$(swift --version 2>&1 | head -1)
    echo "Swift already installed: $CURRENT"
    read -p "Reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Dependencies
echo "Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    binutils git gnupg2 libc6-dev libcurl4-openssl-dev \
    libedit2 libgcc-13-dev libpython3-dev libsqlite3-0 \
    libstdc++-13-dev libxml2-dev libz3-dev pkg-config \
    tzdata unzip zlib1g-dev

# Download Swift
TARBALL="${SWIFT_RELEASE}-${PLATFORM}.tar.gz"
URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/${PLATFORM/./}/${SWIFT_RELEASE}/${TARBALL}"

echo "Downloading ${TARBALL}..."
cd /tmp
wget -q --show-progress "$URL"

# Install
echo "Installing to ${INSTALL_DIR}..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo tar xzf "$TARBALL" -C "$INSTALL_DIR" --strip-components=1

# Add to PATH
PROFILE_LINE="export PATH=${INSTALL_DIR}/usr/bin:\$PATH"
if ! grep -q "$INSTALL_DIR" ~/.bashrc 2>/dev/null; then
    echo "$PROFILE_LINE" >> ~/.bashrc
fi

export PATH="${INSTALL_DIR}/usr/bin:$PATH"

# Cleanup
rm -f /tmp/"$TARBALL"

# Verify
echo ""
echo "=== Swift Installed ==="
swift --version
echo ""
echo "You can now run: swift build, swift test"
echo "Restart your shell or run: source ~/.bashrc"
