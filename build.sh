#!/bin/bash
# Build script for zhell

set -e

echo "Building zhell - Cross-Platform Shell..."

if ! command -v zig &> /dev/null; then
    echo "❌ Zig compiler not found!"
    echo "Please install Zig from https://ziglang.org/"
    echo "Or run: curl -L https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz | tar -xJ"
    exit 1
fi

echo "✅ Zig compiler found: $(zig version)"

# Build the project
echo "Building project..."
zig build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "Run './zig-out/bin/zhell' to start the shell"
    
    # Run tests
    echo "Running tests..."
    zig build test
    
    if [ $? -eq 0 ]; then
        echo "✅ All tests passed!"
    else
        echo "⚠️  Some tests failed"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi