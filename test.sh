#!/bin/bash
#
# Integration test script for clipboard-paste-mcp
#
# Prerequisites:
#   - Go installed
#   - Image in clipboard (e.g., from Cmd+Shift+4 screenshot)
#
# Usage:
#   ./test.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR=$(mktemp -d)
PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
    /bin/rm -rf "$TEST_DIR"
}
trap cleanup EXIT

log_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

log_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

log_skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
}

log_info() {
    echo -e "  $1"
}

echo "================================"
echo "Clipboard Paste MCP - Test Suite"
echo "================================"
echo ""

# ----------------------------------------
# Test 1: Build CLI tool
# ----------------------------------------
echo "Test 1: Build CLI tool"
cd "$SCRIPT_DIR"
if go build -o "$TEST_DIR/paste-cb" ./cmd/paste-cb 2>/dev/null; then
    log_pass "CLI tool builds successfully"
else
    log_fail "CLI tool failed to build"
    exit 1
fi

# ----------------------------------------
# Test 2: Build MCP server
# ----------------------------------------
echo ""
echo "Test 2: Build MCP server"
if go build -o "$TEST_DIR/clipboard-paste-mcp" . 2>/dev/null; then
    log_pass "MCP server builds successfully"
else
    log_fail "MCP server failed to build"
    exit 1
fi

# ----------------------------------------
# Test 3: CLI tool with image in clipboard
# ----------------------------------------
echo ""
echo "Test 3: CLI tool - paste image from clipboard"

OUTPUT=$("$TEST_DIR/paste-cb" "$TEST_DIR" 2>&1) || {
    if echo "$OUTPUT" | grep -q "No image data in clipboard"; then
        log_skip "No image in clipboard - copy a screenshot first"
        echo ""
        echo "================================"
        echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed (1 skipped)"
        echo "================================"
        echo ""
        echo "To run full tests, copy an image to clipboard first:"
        echo "  - Take a screenshot with Cmd+Shift+4"
        echo "  - Or copy any image from a browser/app"
        echo "  - Then run this script again"
        exit 0
    else
        log_fail "CLI tool failed: $OUTPUT"
        exit 1
    fi
}

# Extract filename from output
FILENAME=$(echo "$OUTPUT" | grep -o 'screenshot-[0-9-]*\.png')
if [ -z "$FILENAME" ]; then
    log_fail "Could not parse output filename"
    exit 1
fi

SAVED_FILE="$TEST_DIR/$FILENAME"
if [ -f "$SAVED_FILE" ]; then
    log_pass "CLI tool saves file to specified directory"
    log_info "Saved: $FILENAME"
else
    log_fail "File not created at expected path"
    exit 1
fi

# ----------------------------------------
# Test 4: Verify file is valid PNG
# ----------------------------------------
echo ""
echo "Test 4: Verify saved file is valid PNG"

# Check PNG magic bytes (89 50 4E 47 = \x89PNG)
if head -c 4 "$SAVED_FILE" | xxd -p | grep -q "89504e47"; then
    log_pass "File has valid PNG header"
else
    log_fail "File is not a valid PNG (bad magic bytes)"
    exit 1
fi

# ----------------------------------------
# Test 5: Verify file permissions
# ----------------------------------------
echo ""
echo "Test 5: Verify file permissions"

PERMS=$(stat -f "%Lp" "$SAVED_FILE")
if [ "$PERMS" = "644" ]; then
    log_pass "File permissions are 644 (rw-r--r--)"
else
    log_fail "File permissions are $PERMS, expected 644"
fi

# ----------------------------------------
# Test 6: Verify filename format
# ----------------------------------------
echo ""
echo "Test 6: Verify filename format"

if echo "$FILENAME" | grep -qE '^screenshot-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}\.png$'; then
    log_pass "Filename follows expected format (screenshot-YYYY-MM-DD-HHMMSS.png)"
else
    log_fail "Filename format unexpected: $FILENAME"
fi

# ----------------------------------------
# Test 7: CLI creates directory if missing
# ----------------------------------------
echo ""
echo "Test 7: CLI creates directory if missing"

NEW_DIR="$TEST_DIR/nested/subdir"
OUTPUT=$("$TEST_DIR/paste-cb" "$NEW_DIR" 2>&1)
if [ -d "$NEW_DIR" ]; then
    log_pass "CLI creates nested directories automatically"
else
    log_fail "CLI did not create nested directory"
fi

# ----------------------------------------
# Summary
# ----------------------------------------
echo ""
echo "================================"
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "================================"

if [ $FAIL_COUNT -eq 0 ]; then
    exit 0
else
    exit 1
fi
