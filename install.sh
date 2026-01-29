#!/bin/bash
# Install clipboard-paste-mcp as a user-scoped MCP server in Claude Code

set -e

# Get the directory where this script lives (the repo root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BINARY="$SCRIPT_DIR/clipboard-paste-mcp"

echo "Building clipboard-paste-mcp..."
cd "$SCRIPT_DIR"
go build -o clipboard-paste-mcp

echo "Registering with Claude Code (user scope)..."
claude mcp add --scope user --transport stdio clipboard-paste-mcp -- "$BINARY"

echo ""
echo "✅ Installation complete!"
echo ""
echo "The MCP server is now available system-wide in all Claude Code sessions."
echo ""
echo "Verify with: claude mcp list"
