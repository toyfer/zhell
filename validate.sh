#!/bin/bash
# Simple validation script for Zig syntax

echo "Checking Zig project structure..."

# Check if required files exist
if [ ! -f "build.zig" ]; then
    echo "❌ build.zig not found"
    exit 1
fi

if [ ! -f "src/main.zig" ]; then
    echo "❌ src/main.zig not found"
    exit 1
fi

if [ ! -f "TODO.md" ]; then
    echo "❌ TODO.md not found"
    exit 1
fi

echo "✅ Project structure is correct"

# Check for basic Zig syntax patterns
if grep -q "const std = @import(\"std\");" build.zig; then
    echo "✅ build.zig has correct std import"
else
    echo "❌ build.zig missing std import"
    exit 1
fi

if grep -q "pub fn main()" src/main.zig; then
    echo "✅ src/main.zig has main function"
else
    echo "❌ src/main.zig missing main function"
    exit 1
fi

if grep -q "Shell" src/main.zig; then
    echo "✅ src/main.zig has Shell struct"
else
    echo "❌ src/main.zig missing Shell struct"
    exit 1
fi

echo "✅ All syntax checks passed!"
echo "Note: Full compilation requires Zig to be installed"