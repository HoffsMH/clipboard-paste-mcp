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

	imgData := clipboard.Read(clipboard.FmtImage)
	if len(imgData) == 0 {
		fmt.Println("No image data in clipboard")
		os.Exit(1)
	}

	fmt.Printf("Found %d bytes of image data\n", len(imgData))

	outDir := "."
	if len(os.Args) > 1 {
		outDir = os.Args[1]
	}

	filename := fmt.Sprintf("clipboard-%d.png", time.Now().Unix())
	outPath := filepath.Join(outDir, filename)

	if err := os.WriteFile(outPath, imgData, 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to write: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Saved: %s\n", outPath)
}
