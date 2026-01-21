#!/bin/bash

# AtCoder Libraryを展開してクリップボードにコピー
# Usage: bash ./copy.sh [options] [source_file]
# Options:
#   -l, --light    圧縮版（インデント・空行・コメント削除）

LIGHT_MODE=false
SOURCE_FILE=""

# オプション解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--light)
            LIGHT_MODE=true
            shift
            ;;
        *)
            SOURCE_FILE="$1"
            shift
            ;;
    esac
done

# デフォルトのソースファイル
SOURCE_FILE="${SOURCE_FILE:-main.cpp}"
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

if [ "$LIGHT_MODE" = true ]; then
    echo "Expanding AtCoder Library in $SOURCE_FILE (Light mode)..."

    # 元のコードからマーカー行を見つける（#include <atcoder/all>の次の行）
    MARKER_LINE=$(grep -n '#include <atcoder/all>' "$SOURCE_FILE" | cut -d: -f1)
    if [ -z "$MARKER_LINE" ]; then
        echo "Warning: #include <atcoder/all> not found. Processing entire file."
        python3 "$EXPANDER_SCRIPT" "$SOURCE_FILE" --lib "$AC_LIBRARY_PATH" -c | \
        sed 's/^[[:space:]]*//' | \
        sed '/^$/d' | \
        sed 's|//.*$||' | \
        sed '/^$/d' | \
        pbcopy
    else
        # 元のコード（AC Library includeより後）を取得
        MARKER_LINE=$((MARKER_LINE + 1))
        USER_CODE=$(tail -n +$MARKER_LINE "$SOURCE_FILE")

        # 展開されたコードを取得
        EXPANDED=$(python3 "$EXPANDER_SCRIPT" "$SOURCE_FILE" --lib "$AC_LIBRARY_PATH" -c 2>/dev/null)

        # 元のコードが展開されたコードのどこから始まるかを見つける
        # 最初の非空白行をマーカーとして使用
        FIRST_USER_LINE=$(echo "$USER_CODE" | grep -v '^[[:space:]]*$' | head -1 | sed 's/[]\/$*.^[]/\\&/g')

        if [ -n "$FIRST_USER_LINE" ]; then
            # AC Library部分（元のコードより前）を抽出して軽量化
            AC_PART=$(echo "$EXPANDED" | sed "/$FIRST_USER_LINE/,\$d" | \
                sed 's/^[[:space:]]*//' | \
                sed '/^$/d' | \
                sed 's|//.*$||' | \
                sed '/^$/d')

            # ユーザーコード部分を抽出（軽量化しない）
            USER_PART=$(echo "$EXPANDED" | sed -n "/$FIRST_USER_LINE/,\$p")

            # 結合してクリップボードにコピー
            {
                echo "$AC_PART"
                echo "$USER_PART"
            } | pbcopy
        else
            echo "Warning: Could not identify user code boundary. Processing entire file."
            echo "$EXPANDED" | \
            sed 's/^[[:space:]]*//' | \
            sed '/^$/d' | \
            sed 's|//.*$||' | \
            sed '/^$/d' | \
            pbcopy
        fi
    fi
else
    echo "Expanding AtCoder Library in $SOURCE_FILE..."

    # 通常版（既存の処理）
    python3 "$EXPANDER_SCRIPT" "$SOURCE_FILE" --lib "$AC_LIBRARY_PATH" -c | pbcopy
fi

if [ $? -eq 0 ]; then
    if [ "$LIGHT_MODE" = true ]; then
        CHAR_COUNT=$(pbpaste | wc -c | tr -d ' ')
        echo "✓ Code expanded (compressed) and copied to clipboard!"
        echo "  Size: $CHAR_COUNT characters"
    else
        echo "✓ Code expanded and copied to clipboard!"
    fi
    echo "  You can now paste it to Codeforces or other online judges."
else
    echo "Error: Failed to expand code"
    exit 1
fi
