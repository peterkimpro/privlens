#!/bin/bash
# setup-hooks.sh — Install git hooks for the Privlens repo
# Usage: bash Scripts/setup-hooks.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

# Pre-push hook
cp "$REPO_ROOT/Scripts/pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"

echo "Done. Pre-push hook installed."
echo "It will run Linux validation before each push."
echo "Skip with: git push --no-verify"
