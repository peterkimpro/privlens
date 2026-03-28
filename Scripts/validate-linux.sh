#!/bin/bash
# validate-linux.sh — Run Linux build + tests locally via Docker before pushing
# Mirrors exactly what GitHub Actions runs, so CI failures are caught early.
#
# Prerequisites: Docker must be running.
# Usage: bash Scripts/validate-linux.sh
#
# This script is also invoked by the pre-push git hook.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SWIFT_IMAGE="swift:6.0"

red()   { printf "\033[1;31m%s\033[0m\n" "$*"; }
green() { printf "\033[1;32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[1;33m%s\033[0m\n" "$*"; }

echo "=== Privlens Linux Validation ==="
echo ""

# --------------------------------------------------------------------------
# Step 1: Static lint checks (no Docker needed)
# --------------------------------------------------------------------------
echo "--- Step 1: Static lint checks ---"
if ! bash "$REPO_ROOT/Scripts/lint-swift-concurrency.sh"; then
    red "Static lint failed. Fix the issues above before pushing."
    exit 1
fi
echo ""

# --------------------------------------------------------------------------
# Step 2: Docker-based Linux build + test
# --------------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
    yellow "WARNING: Docker not found. Skipping Linux build validation."
    yellow "Install Docker to enable local Linux CI validation."
    exit 0
fi

if ! docker info &>/dev/null 2>&1; then
    yellow "WARNING: Docker daemon not running. Skipping Linux build validation."
    exit 0
fi

echo "--- Step 2: Linux build (swift build --target PrivlensCore) ---"
if ! docker run --rm -v "$REPO_ROOT:/workspace" -w /workspace "$SWIFT_IMAGE" \
    swift build --target PrivlensCore 2>&1; then
    red "Linux build FAILED. Fix compilation errors before pushing."
    exit 1
fi
green "Linux build succeeded."
echo ""

echo "--- Step 3: Linux tests (swift test) ---"
if ! docker run --rm -v "$REPO_ROOT:/workspace" -w /workspace "$SWIFT_IMAGE" \
    swift test 2>&1; then
    red "Linux tests FAILED. Fix test failures before pushing."
    exit 1
fi
green "Linux tests passed."
echo ""

green "=== All Linux validations passed. Safe to push. ==="
