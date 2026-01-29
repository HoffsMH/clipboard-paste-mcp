# Clipboard Paste MCP Server

An MCP (Model Context Protocol) server that allows Claude Code to paste screenshots from your clipboard into a temporary directory for analysis.

## What it does

This server exposes a tool called `paste_clipboard_screenshot` that:
1. Creates a temporary directory (`/tmp/claude-clipboard-{timestamp}/`)
2. Runs your `~/bin/paste-cb` script to save clipboard contents
3. Returns the file path so Claude can read and analyze it

## Setup

### 1. Build the MCP Server

```bash
cd ~/code/unpaid/clipboard-paste-mcp
go build -o clipboard-paste-mcp
```

### 2. Add to Claude Code

The server is already configured at the **user scope** (available in all projects):

```bash
claude mcp list
# Should show: clipboard-paste-mcp: ✓ Connected
```

If you need to add it manually:

```bash
claude mcp add --scope user --transport stdio clipboard-paste-mcp -- \
  /Users/mh/code/unpaid/clipboard-paste-mcp/clipboard-paste-mcp
```

### 3. Verify Configuration

```bash
# List all MCP servers
claude mcp list

# Get details about this server
claude mcp get clipboard-paste-mcp
```

## Usage

In any Claude Code session, you can now say:

- "Use the paste clipboard screenshot tool"
- "Paste and analyze my clipboard"
- "What's in my clipboard?" (Claude will use the tool automatically)

Claude will:
1. Call the `paste_clipboard_screenshot` tool
2. Get the file path from the tool response
3. Use the Read tool to view the screenshot
4. Analyze and discuss it with you

## How It Works

```
User copies screenshot → Clipboard
                            ↓
User asks Claude to analyze clipboard
                            ↓
Claude calls paste_clipboard_screenshot tool (via MCP)
                            ↓
MCP Server runs: cd /tmp/... && ~/bin/paste-cb
                            ↓
Returns file path to Claude
                            ↓
Claude reads the file and analyzes it
```

## Requirements

- Go 1.21+
- `~/bin/paste-cb` script that saves clipboard contents to the current directory
- Claude Code with MCP support

## Files

- `main.go` - MCP server implementation using official Go SDK
- `clipboard-paste-mcp` - Compiled binary (6.8MB)
- `.gitignore` - Standard Go gitignore
- `README.md` - This file
