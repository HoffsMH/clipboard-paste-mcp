//go:build darwin

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"golang.design/x/clipboard"
)

func main() {
	if err := clipboard.Init(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to init clipboard: %v\n", err)
		os.Exit(1)
	}

	// Default to current directory, or use first arg
	targetDir := "."
	if len(os.Args) > 1 {
		targetDir = os.Args[1]
	}

	// Ensure target directory exists
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create directory: %v\n", err)
		os.Exit(1)
	}

	// Try to read image data
	imgData := clipboard.Read(clipboard.FmtImage)
	if len(imgData) == 0 {
		fmt.Fprintln(os.Stderr, "No image data in clipboard")
		os.Exit(1)
	}

	// Generate filename with timestamp (matching original script format)
	timestamp := time.Now().Format("2006-01-02-150405")
	filename := fmt.Sprintf("screenshot-%s.png", timestamp)
	outPath := filepath.Join(targetDir, filename)

	if err := os.WriteFile(outPath, imgData, 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to write file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Saved screenshot as %s\n", filename)
}
