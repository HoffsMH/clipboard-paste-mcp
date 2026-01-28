# Clipboard Paste MCP Server

An MCP (Model Context Protocol) server that allows Claude Code to paste screenshots from your clipboard into a temporary directory for analysis.

## What it does

This server exposes a tool called `paste_clipboard_screenshot` that:
1. Creates a temporary directory
2. Runs your `~/bin/paste-cb` script to save clipboard contents
3. Returns the file path so Claude can read and analyze it

## Setup

### Install Dependencies

```bash
go get github.com/modelcontextprotocol/go-sdk
```

### Build

```bash
go build -o clipboard-paste-mcp
```

### Configure Claude Code

Add to your Claude Code config (`~/.claude/config.json`):

```json
{
  "mcpServers": {
    "clipboard-paste": {
      "command": "/Users/mh/code/unpaid/clipboard-paste-mcp/clipboard-paste-mcp"
    }
  }
}
```

## Usage

Once configured, you can ask Claude to use the clipboard paste tool:

"Use the paste clipboard screenshot tool to analyze what's on my clipboard"

Claude will then be able to call the tool, get the file path, and read the image for analysis.

## Requirements

- Go 1.21+
- `~/bin/paste-cb` script that saves clipboard contents to the current directory
