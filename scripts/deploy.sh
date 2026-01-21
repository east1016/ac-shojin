#!/bin/bash

# AtCoder Libraryを展開してdeploy.cppに出力
# Usage: bash ./deploy.sh [source_file] [output_file]

SOURCE_FILE="${1:-main.cpp}"
OUTPUT_FILE="${2:-deploy.cpp}"
AC_LIBRARY_PATH="./lib/ac-library"
EXPANDER_SCRIPT="$AC_LIBRARY_PATH/expander.py"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file '$SOURCE_FILE' not found"
    exit 1
fi

if [ ! -f "$EXPANDER_SCRIPT" ]; then
    echo "Error: Expander script not found at '$EXPANDER_SCRIPT'"
    exit 1
fi

echo "Expanding AtCoder Library in $SOURCE_FILE..."

# expander.pyを使ってAtCoder Libraryを展開
python3 "$EXPANDER_SCRIPT" "$SOURCE_FILE" --lib "$AC_LIBRARY_PATH" -c > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Code expanded and saved to $OUTPUT_FILE"
    echo "  You can submit this file to online judges."

    # クリップボードにもコピー
    cat "$OUTPUT_FILE" | pbcopy
    echo "✓ Also copied to clipboard!"
else
    echo "Error: Failed to expand code"
    exit 1
fi
