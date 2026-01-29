package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// Empty struct for tool args since we don't need any input parameters
type emptyArgs struct{}

func pasteClipboard(ctx context.Context, req *mcp.CallToolRequest, args emptyArgs) (*mcp.CallToolResult, any, error) {
	// Create temp directory
	tempDir := fmt.Sprintf("/tmp/claude-clipboard-%d", time.Now().Unix())
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return nil, nil, fmt.Errorf("failed to create temp directory: %w", err)
	}

	// Run paste-cb script in the temp directory
	cmd := exec.Command("bash", "-c", fmt.Sprintf("cd %s && ~/bin/paste-cb", tempDir))
	if err := cmd.Run(); err != nil {
		return nil, nil, fmt.Errorf("failed to run paste-cb: %w", err)
	}

	// Find the pasted file
	files, err := filepath.Glob(filepath.Join(tempDir, "*"))
	if err != nil || len(files) == 0 {
		return nil, nil, fmt.Errorf("no files found in temp directory")
	}

	return &mcp.CallToolResult{
		Content: []mcp.Content{
			&mcp.TextContent{
				Text: fmt.Sprintf("Screenshot saved to: %s", files[0]),
			},
		},
	}, nil, nil
}

func main() {
	server := mcp.NewServer(&mcp.Implementation{
		Name:    "clipboard-paste",
		Version: "1.0.0",
	}, nil)

	tool := &mcp.Tool{
		Name:        "paste_clipboard_screenshot",
		Description: "Paste screenshot from clipboard to temp directory and return path for Claude to read",
	}

	mcp.AddTool(server, tool, pasteClipboard)

	if err := server.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
		log.Fatal(err)
	}
}
