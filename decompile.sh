#!/bin/bash

# Script to decompile HytaleServer.jar using procyon-decompiler

JAR_FILE="HytaleServer.jar"
OUTPUT_DIR="decompiled"

# Check if HytaleServer.jar exists
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: $JAR_FILE not found in current directory"
    exit 1
fi

# Check if decompiled code already exists
if [ -d "$OUTPUT_DIR" ] && [ "$(ls -A $OUTPUT_DIR 2>/dev/null)" ]; then
    echo "Warning: $OUTPUT_DIR directory already exists and contains files"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Decompilation cancelled"
        exit 0
    fi
    echo "Removing existing $OUTPUT_DIR directory..."
    rm -rf "$OUTPUT_DIR"
fi

# Check if procyon-decompiler is available
if ! command -v procyon-decompiler &> /dev/null; then
    echo "Error: procyon-decompiler not found"
    echo "Please install it first. You can install it via:"
    echo "  pacman -S procyon-decompiler"
    echo "  or download from: https://github.com/mstrobel/procyon"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Decompile the jar file
echo "Decompiling $JAR_FILE to $OUTPUT_DIR..."
procyon-decompiler "$JAR_FILE" -o "$OUTPUT_DIR"

if [ $? -eq 0 ]; then
    echo "Decompilation completed successfully!"
else
    echo "Error: Decompilation failed"
    exit 1
fi
