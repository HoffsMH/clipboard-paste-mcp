#!/bin/bash
# Install clipboard-paste-mcp (MCP server) and paste-cb (CLI tool)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BINARY="$SCRIPT_DIR/clipboard-paste-mcp"
GOBIN_DIR="$HOME/go/bin"

# Color output helpers
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# Check prerequisites
echo "Checking prerequisites..."

# Check for Go
if ! command -v go &> /dev/null; then
    red "Error: Go is not installed"
    echo "Install Go from https://golang.org/dl/ or via package manager:"
    echo "  brew install go"
    echo "  asdf install golang latest"
    exit 1
fi
echo "  ✓ Go $(go version | awk '{print $3}')"

# Check for Xcode CLI tools (required for CGo)
if ! xcode-select -p &> /dev/null; then
    red "Error: Xcode Command Line Tools not installed"
    echo "Install with: xcode-select --install"
    exit 1
fi
echo "  ✓ Xcode CLI tools"

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    red "Error: Claude Code CLI not found"
    echo "Install from: https://claude.ai/claude-code"
    exit 1
fi
echo "  ✓ Claude Code CLI"

cd "$SCRIPT_DIR"

# Create GOBIN directory if needed
if [ ! -d "$GOBIN_DIR" ]; then
    echo ""
    echo "Creating $GOBIN_DIR..."
    mkdir -p "$GOBIN_DIR"
fi

# Install CLI tool
echo ""
echo "Installing paste-cb CLI tool..."
GOBIN="$GOBIN_DIR" go install ./cmd/paste-cb
echo "  ✓ Installed to $GOBIN_DIR/paste-cb"

# Build MCP server
echo ""
echo "Building clipboard-paste-mcp server..."
go build -o clipboard-paste-mcp
echo "  ✓ Built $BINARY"

# Register MCP server (handle already-exists case)
echo ""
echo "Registering MCP server with Claude Code..."
if claude mcp list 2>/dev/null | grep -q "^clipboard-paste-mcp:"; then
    echo "  Updating existing registration..."
    claude mcp remove --scope user clipboard-paste-mcp 2>/dev/null || true
fi
claude mcp add --scope user --transport stdio clipboard-paste-mcp -- "$BINARY"
echo "  ✓ Registered with Claude Code (user scope)"

# Verify installation
echo ""
green "Installation complete!"
echo ""
echo "Installed:"
echo "  • paste-cb CLI:  $GOBIN_DIR/paste-cb"
echo "  • MCP server:    $BINARY"
echo ""

# Check if GOBIN is in PATH
if [[ ":$PATH:" != *":$GOBIN_DIR:"* ]]; then
    yellow "Note: $GOBIN_DIR is not in your PATH"
    echo "Add to your shell config (~/.zshrc or ~/.bashrc):"
    echo "  export PATH=\"\$HOME/go/bin:\$PATH\""
    echo ""
fi

echo "Verify with:"
echo "  claude mcp list"
echo "  paste-cb --help"
