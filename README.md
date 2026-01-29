# Clipboard Paste MCP

An MCP (Model Context Protocol) server and CLI tool that allows Claude Code to paste screenshots from your clipboard for analysis.

## What it does

This server exposes a tool called `paste_clipboard_screenshot` that:
1. Reads image data directly from the macOS clipboard using CGo
2. Saves it to a temporary directory
3. Returns the file path so Claude can read and analyze the image

## Prerequisites

- **Go 1.21+**
- **Xcode Command Line Tools** (for CGo compilation)
  ```bash
  xcode-select --install
  ```
- **Claude Code** with MCP support

## Installation

Clone the repo and run the install script:

```bash
git clone https://github.com/HoffsMH/clipboard-paste-mcp.git
cd clipboard-paste-mcp
./install.sh
```

The install script will:
1. Install the `paste-cb` CLI tool to `$HOME/go/bin`
2. Build the MCP server binary
3. Register it with Claude Code at **user scope** (available system-wide)

**Note:** Ensure `$HOME/go/bin` is in your PATH to use the CLI tool directly.

### Verify Installation

```bash
# List all MCP servers
claude mcp list
# Should show: clipboard-paste-mcp: ✓ Connected

# Get details about this server
claude mcp get clipboard-paste-mcp
```

### Manual Installation

If you prefer to install manually:

```bash
# Build and install CLI tool
GOBIN=$HOME/go/bin go install ./cmd/paste-cb

# Build MCP server
go build -o clipboard-paste-mcp

# Register with Claude Code
claude mcp add --scope user --transport stdio clipboard-paste-mcp -- \
  "$(pwd)/clipboard-paste-mcp"
```

## MCP Configuration

### Configuration File Location

Claude Code stores MCP server configurations in `~/.claude.json`. User-scoped servers appear under the `mcpServers` key:

```json
{
  "mcpServers": {
    "clipboard-paste-mcp": {
      "type": "stdio",
      "command": "/absolute/path/to/clipboard-paste-mcp",
      "args": [],
      "env": {}
    }
  }
}
```

### Configuration Details

| Field | Description |
|-------|-------------|
| `type` | Transport type. Always `"stdio"` for this server |
| `command` | **Absolute path** to the server binary (required) |
| `args` | Command-line arguments (empty for this server) |
| `env` | Environment variables (none required) |

**Important:** The `command` field must be an absolute path. Relative paths and `~` expansion are not supported in the JSON config. The install script handles this automatically.

### Scopes

- **User scope** (recommended): Available in all projects. Config lives in `~/.claude.json` under `mcpServers`
- **Project scope**: Only available in one project. Config lives in `~/.claude.json` under `projects.<path>.mcpServers`

The install script registers at user scope so the tool is available everywhere.

## Usage

### MCP Tool (in Claude Code)

In any Claude Code session, you can now say:

- "Use the paste clipboard screenshot tool"
- "Paste and analyze my clipboard"
- "What's in my clipboard?"

Claude will:
1. Call the `paste_clipboard_screenshot` tool
2. Get the file path from the tool response
3. Use the Read tool to view the screenshot
4. Analyze and discuss it with you

### CLI Tool

```bash
# Paste clipboard image to current directory
paste-cb

# Paste to specific directory
paste-cb /path/to/dir
```

Output: `screenshot-YYYY-MM-DD-HHMMSS.png`

## How It Works

```
User copies screenshot to clipboard
            ↓
User asks Claude to analyze clipboard
            ↓
Claude calls paste_clipboard_screenshot tool (via MCP)
            ↓
MCP Server uses golang.design/x/clipboard (CGo → NSPasteboard)
            ↓
Image saved to temp directory, path returned to Claude
            ↓
Claude reads the file and analyzes it
```

## Architecture

The implementation uses `golang.design/x/clipboard`, which provides direct access to macOS NSPasteboard via CGo. No shell scripts or external commands are needed.

## Files

| File | Purpose |
|------|---------|
| `main.go` | MCP server implementation |
| `cmd/paste-cb/main.go` | CLI tool implementation |
| `install.sh` | Installation script |
| `test.sh` | Integration test script |

## Testing

### Automated Integration Tests

Run the integration test script:

```bash
# First, copy an image to clipboard (e.g., Cmd+Shift+4 for screenshot)
./test.sh
```

The script tests:
- CLI and MCP server build successfully
- CLI saves clipboard image to specified directory
- Output file is valid PNG with correct permissions (644)
- Filename format matches `screenshot-YYYY-MM-DD-HHMMSS.png`
- CLI creates directories automatically if missing

### Manual Testing

**CLI Tool:**
```bash
# 1. Copy a screenshot to clipboard (Cmd+Shift+4, select area)
# 2. Run CLI tool
$HOME/go/bin/paste-cb /tmp/test-clipboard

# 3. Verify output
ls -la /tmp/test-clipboard/screenshot-*.png
file /tmp/test-clipboard/screenshot-*.png  # Should show "PNG image data"
```

**MCP Tool (in Claude Code):**
1. Copy a screenshot to clipboard
2. In Claude Code, say: "Use the paste clipboard screenshot tool"
3. Claude will save the image and read it for analysis

**Verify MCP Registration:**
```bash
claude mcp list                      # Should show clipboard-paste-mcp connected
claude mcp get clipboard-paste-mcp   # Shows server details and status
```

## Platform Support

Currently **macOS only**. The clipboard library uses CGo with NSPasteboard for clipboard access.

## Troubleshooting

**"No image data in clipboard"**
- Make sure you've copied an image (screenshot, image from browser, etc.)
- Text or file copies won't work - clipboard must contain image data

**Build fails with CGo errors**
- Install Xcode Command Line Tools: `xcode-select --install`
- Ensure you have a working C compiler: `cc --version`

**MCP server not connecting**
- Verify registration: `claude mcp list`
- Check the binary path: `claude mcp get clipboard-paste-mcp`
- Ensure the binary exists at the registered path
