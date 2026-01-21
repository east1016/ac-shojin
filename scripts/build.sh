#!/bin/bash

# Build script for competitive programming
# AtCoder C++ 23 (gcc 14.2.0) 互換環境
# Interactive problem friendly

set -e

# compile_flags.shから共通フラグを読み込む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/compile_flags.sh"

# 絶対パスを相対パスに変換する関数
to_relative_path() {
    local path="$1"
    # PROJ_ROOTからの相対パスに変換
    echo "${path#$PROJ_ROOT/}"
}

# エラーメッセージ内の絶対パスを相対パスに変換
filter_paths() {
    sed "s|$PROJ_ROOT/||g"
}

# Default values
SOURCE_FILE="${PROJ_ROOT}/main.cpp"
OUTPUT_FILE="${PROJ_ROOT}/build/a.out"
INPUT_FILE="${PROJ_ROOT}/ain.txt"
OUTPUT_LOG="${PROJ_ROOT}/aout.txt"
ERROR_LOG="${PROJ_ROOT}/aerr.log"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  work          Compile and run with run.sh (default, non-interactive)"
    echo "  debug         Run debug mode with gen_run.sh"
    echo "  build         Just compile main.cpp"
    echo "  run           Compile and run normally (stdin/stdout)"
    echo "  test          Compile and run with I/O files"
    echo "  interactive   Compile and run (interactive, no buffering)"
    echo "  tty           Compile and run with pseudo-TTY (strong interactive)"
    echo "  -s <file>     Specify source file (default: main.cpp)"
    echo "  -h            Display this help message"
    exit 1
}

# Compile function
compile() {
    local src_file=$1
    local rel_src=$(to_relative_path "$src_file")
    local rel_out=$(to_relative_path "$OUTPUT_FILE")
    echo "Compiling ${rel_src}..." >&2
    local flags=$(get_all_flags)
    # コンパイル時のwarningは標準エラー出力に表示（aerrには出力しない）
    # パスをフィルタリングして表示
    local tmp_err=$(mktemp)
    if g++ ${flags} -o ${OUTPUT_FILE} ${src_file} 2> "$tmp_err"; then
        # 成功時でも警告があれば表示
        if [ -s "$tmp_err" ]; then
            filter_paths < "$tmp_err" >&2
        fi
        rm -f "$tmp_err"
        echo "Compilation successful!" >&2
        return 0
    else
        # 失敗時
        filter_paths < "$tmp_err" >&2
        rm -f "$tmp_err"
        echo "Compilation failed!" >&2
        return 1
    fi
}

# Default behavior
if [ $# -eq 0 ]; then
    "$SCRIPT_DIR/run.sh" -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
    exit 0
fi

case "$1" in
    work)
        "$SCRIPT_DIR/run.sh" -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
        ;;
    debug)
        "$SCRIPT_DIR/gen_run.sh" -g "${PROJ_ROOT}/templates/testcase_generate.cpp" -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
        ;;
    build)
        compile ${SOURCE_FILE} || exit 1
        ;;
    run)
        compile ${SOURCE_FILE} || exit 1
        "${OUTPUT_FILE}"
        ;;
    test)
        compile ${SOURCE_FILE} || exit 1
        "${OUTPUT_FILE}" < ${INPUT_FILE} > ${OUTPUT_LOG} 2> ${ERROR_LOG}
        echo "Output written to $(to_relative_path ${OUTPUT_LOG})"
        echo "Errors written to $(to_relative_path ${ERROR_LOG})"
        ;;
    interactive)
        compile ${SOURCE_FILE} || exit 1
        echo "Running in interactive mode (no buffering)..."
        stdbuf -i0 -o0 -e0 "${OUTPUT_FILE}"
        ;;
    tty)
        compile ${SOURCE_FILE} || exit 1
        echo "Running in pseudo-TTY mode..."
        script -q /dev/null "${OUTPUT_FILE}"
        ;;
    -s)
        if [ -n "$2" ]; then
            SOURCE_FILE=$2
            compile ${SOURCE_FILE} || exit 1
        else
            echo "Error: -s requires a source file argument"
            usage
        fi
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
esac
