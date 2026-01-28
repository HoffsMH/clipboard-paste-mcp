package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"
	"github.com/modelcontextprotocol/go-sdk/server"
)

func main() {
	s := server.NewStdioServer("clipboard-paste", "1.0.0")

	s.AddTool("paste_clipboard_screenshot",
		"Paste screenshot from clipboard to temp directory and return path for Claude to read",
		func(args map[string]interface{}) (*mcp.ToolResponse, error) {
			// Create temp directory
			tempDir := fmt.Sprintf("/tmp/claude-clipboard-%d", time.Now().Unix())
			if err := os.MkdirAll(tempDir, 0755); err != nil {
				return nil, fmt.Errorf("failed to create temp directory: %w", err)
			}

			// Run paste-cb script in the temp directory
			cmd := exec.Command("bash", "-c", fmt.Sprintf("cd %s && ~/bin/paste-cb", tempDir))
			if err := cmd.Run(); err != nil {
				return nil, fmt.Errorf("failed to run paste-cb: %w", err)
			}

			// Find the pasted file
			files, err := filepath.Glob(filepath.Join(tempDir, "*"))
			if err != nil || len(files) == 0 {
				return nil, fmt.Errorf("no files found in temp directory")
			}

			return &mcp.ToolResponse{
				Content: []mcp.Content{{
					Type: "text",
					Text: fmt.Sprintf("Screenshot saved to: %s", files[0]),
				}},
			}, nil
		},
	)

	if err := s.Serve(); err != nil {
		fmt.Fprintf(os.Stderr, "Server error: %v\n", err)
		os.Exit(1)
	}
}
