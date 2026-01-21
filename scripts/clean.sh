#!/bin/bash
# clean.sh - Clean temporary files and directories

set -e

echo "[clean.sh] Cleaning temporary files..."

# Clear output files (keep files, empty contents)
if [ -f "aout.txt" ]; then
    echo "  - Clearing aout.txt"
    : > aout.txt
fi

if [ -f "aerr.log" ]; then
    echo "  - Clearing aerr.log"
    : > aerr.log
fi

if [ -f "ain.txt" ]; then
    echo "  - Clearing ain.txt"
    : > ain.txt
fi

# Clean tmp directory contents
if [ -d "tmp" ]; then
    echo "  - Cleaning tmp directory"
    rm -rf tmp/*
fi

# Clean build directory contents
if [ -d "build" ]; then
    echo "  - Cleaning build directory"
    rm -rf build/*
fi

echo "[clean.sh] Done!"
