//go:build !darwin

package main

import (
	"fmt"
	"os"
	"runtime"
)

func main() {
	fmt.Fprintf(os.Stderr, "paste-cb is only supported on macOS (darwin).\n")
	fmt.Fprintf(os.Stderr, "Current platform: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Fprintf(os.Stderr, "\nThe clipboard library uses macOS-specific APIs (NSPasteboard via CGo).\n")
	os.Exit(1)
}
