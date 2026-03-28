#!/bin/bash
# lint-swift-concurrency.sh — Static checks for common Swift concurrency & Linux build issues
# Catches problems BEFORE they reach CI:
#   1. NSLock.lock()/unlock() inside async functions
#   2. Missing imports for Linux stubs
#   3. Platform-specific APIs used outside #if guards
#
# Usage: bash Scripts/lint-swift-concurrency.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

red()   { printf "\033[1;31m%s\033[0m\n" "$*"; }
green() { printf "\033[1;32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[1;33m%s\033[0m\n" "$*"; }

echo "=== Swift Concurrency & Linux Lint ==="
echo ""

# --------------------------------------------------------------------------
# Check 1: NSLock.lock() / unlock() directly inside async functions
# Pattern: find functions marked "async" whose body contains lock.lock()
# The safe pattern is to call a sync helper that does the locking.
# --------------------------------------------------------------------------
echo "--- Check 1: NSLock usage inside async functions ---"

TMPFILE=$(mktemp)
find "$REPO_ROOT/Sources" "$REPO_ROOT/Tests" -name "*.swift" | sort | while IFS= read -r file; do
    awk '
    /func .*async/ { in_async = 1; brace_depth = 0 }
    in_async && /{/ { brace_depth++ }
    in_async && /}/ { brace_depth--; if (brace_depth <= 0) in_async = 0 }
    in_async && /\.(lock|unlock)\(\)/ {
        printf "  ERROR: %s:%d — NSLock call inside async function: %s\n", FILENAME, NR, $0
    }
    ' "$file"
done > "$TMPFILE"

if [ -s "$TMPFILE" ]; then
    cat "$TMPFILE"
    ERRORS=$((ERRORS + $(wc -l < "$TMPFILE")))
else
    green "  PASS: No NSLock calls inside async functions"
fi
rm -f "$TMPFILE"

# --------------------------------------------------------------------------
# Check 2: Files in PrivlensCore that lack import Foundation
# --------------------------------------------------------------------------
echo ""
echo "--- Check 2: All PrivlensCore .swift files import Foundation (or are guarded) ---"

CHECK2_OK=true
find "$REPO_ROOT/Sources/PrivlensCore" -name "*.swift" | sort | while IFS= read -r file; do
    # Skip files that are entirely wrapped in #if canImport(SwiftUI/UIKit)
    first_code=$(grep -v '^\s*//' "$file" | grep -v '^\s*$' | head -1)
    if [[ "$first_code" == "#if canImport(SwiftUI)"* ]] || [[ "$first_code" == "#if canImport(UIKit)"* ]]; then
        continue
    fi

    if ! grep -q "^import Foundation" "$file"; then
        yellow "  WARN: $file — missing 'import Foundation' at top level"
    fi
done

# --------------------------------------------------------------------------
# Check 3: Platform-specific API types used outside #if guards
# --------------------------------------------------------------------------
echo ""
echo "--- Check 3: Platform APIs outside #if guards ---"

TMPFILE2=$(mktemp)
PLATFORM_APIS="UIImage|UIColor|UIViewController|UIApplication|NSImage|NSColor|VNDocumentCameraViewController|SKStoreReviewController"

find "$REPO_ROOT/Sources/PrivlensCore" -name "*.swift" | sort | while IFS= read -r file; do
    awk -v apis="$PLATFORM_APIS" '
    BEGIN { in_guard = 0; guard_depth = 0 }
    /^#if canImport\(/ || /^#if os\(/ || /^#if targetEnvironment/ || /^#if ENABLE_/ {
        in_guard = 1; guard_depth++
    }
    /^#else/ { /* still guarded */ }
    /^#endif/ {
        guard_depth--
        if (guard_depth <= 0) { in_guard = 0; guard_depth = 0 }
    }
    !in_guard {
        line = $0
        gsub(/\/\/.*/, "", line)
        if (match(line, apis)) {
            printf "  WARN: %s:%d — platform API outside #if guard: %s\n", FILENAME, NR, $0
        }
    }
    ' "$file"
done > "$TMPFILE2"

if [ -s "$TMPFILE2" ]; then
    cat "$TMPFILE2"
else
    green "  PASS: No unguarded platform API usage"
fi
rm -f "$TMPFILE2"

# --------------------------------------------------------------------------
# Check 4: @unchecked Sendable classes — async funcs must not directly use lock
# --------------------------------------------------------------------------
echo ""
echo "--- Check 4: @unchecked Sendable classes use sync lock helpers ---"

TMPFILE3=$(mktemp)
find "$REPO_ROOT/Sources" -name "*.swift" | sort | while IFS= read -r file; do
    if grep -q "@unchecked Sendable" "$file" && grep -q "NSLock" "$file"; then
        awk '
        /func .*(async)/ && /(public|internal)/ {
            in_async = 1; brace_depth = 0
        }
        in_async && /{/ { brace_depth++ }
        in_async && /}/ { brace_depth--; if (brace_depth <= 0) in_async = 0 }
        in_async && /lock\.(lock|unlock)\(\)/ {
            printf "  ERROR: %s:%d — async func directly uses lock: %s\n", FILENAME, NR, $0
        }
        ' "$file"
    fi
done > "$TMPFILE3"

if [ -s "$TMPFILE3" ]; then
    cat "$TMPFILE3"
    ERRORS=$((ERRORS + $(wc -l < "$TMPFILE3")))
else
    green "  PASS: All @unchecked Sendable classes use sync helpers"
fi
rm -f "$TMPFILE3"

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "================================"
if [ "$ERRORS" -gt 0 ]; then
    red "FAILED: $ERRORS issue(s) found"
    exit 1
else
    green "ALL CHECKS PASSED"
    exit 0
fi
