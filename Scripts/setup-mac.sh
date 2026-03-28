#!/bin/bash
# Privlens Mac Setup Script
# Run this after cloning the repo on your Mac

set -e

echo "🔧 Setting up Privlens development environment..."

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Install Xcode from the App Store."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
echo "✅ Found $XCODE_VERSION"

# Check Swift version
SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "✅ $SWIFT_VERSION"

# Resolve Swift packages
echo "📦 Resolving Swift packages..."
swift package resolve

# Open in Xcode
echo "🚀 Opening Privlens in Xcode..."
echo ""
echo "IMPORTANT: After Xcode opens:"
echo "  1. Select your Development Team in Signing & Capabilities"
echo "  2. Set the bundle identifier to: com.peterkimpro.privlens"
echo "  3. Select an iOS 26+ simulator or your device"
echo "  4. Press Cmd+R to build and run"
echo ""

# If xcodeproj exists, open it; otherwise open the package
if [ -d "App/Privlens.xcodeproj" ]; then
    open "App/Privlens.xcodeproj"
else
    echo "⚠️  No .xcodeproj found. You need to create one in Xcode:"
    echo "  1. Open Xcode -> File -> New -> Project -> App"
    echo "  2. Name: Privlens, Bundle ID: com.peterkimpro.privlens"
    echo "  3. Add local package dependency: ../ (the repo root)"
    echo "  4. Import PrivlensUI and PrivlensCore in the app target"
    echo "  5. Replace the generated ContentView with: import PrivlensUI; use ContentView()"
fi
