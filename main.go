//go:build darwin

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"
	"golang.design/x/clipboard"
)

// Empty struct for tool args since we don't need any input parameters
type emptyArgs struct{}

func pasteClipboard(ctx context.Context, req *mcp.CallToolRequest, args emptyArgs) (*mcp.CallToolResult, any, error) {
	// Read image data from clipboard
	imgData := clipboard.Read(clipboard.FmtImage)
	if len(imgData) == 0 {
		return nil, nil, fmt.Errorf("no image data in clipboard")
	}

	// Create temp directory using os.TempDir() for cross-platform compatibility
	tempDir := filepath.Join(os.TempDir(), fmt.Sprintf("claude-clipboard-%d", time.Now().Unix()))
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return nil, nil, fmt.Errorf("failed to create temp directory: %w", err)
	}

	// Generate filename with timestamp
	timestamp := time.Now().Format("2006-01-02-150405")
	filename := fmt.Sprintf("screenshot-%s.png", timestamp)
	outPath := filepath.Join(tempDir, filename)

	// Write image to file
	if err := os.WriteFile(outPath, imgData, 0644); err != nil {
		return nil, nil, fmt.Errorf("failed to write file: %w", err)
	}

	return &mcp.CallToolResult{
		Content: []mcp.Content{
			&mcp.TextContent{
				Text: fmt.Sprintf("Screenshot saved to: %s", outPath),
			},
		},
	}, nil, nil
}

func main() {
	if err := clipboard.Init(); err != nil {
		log.Fatalf("Failed to init clipboard: %v", err)
	}

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
