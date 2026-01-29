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
MEASURE_TIME=0

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
    echo "  -t, --time    Measure and display execution time"
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

    local start_time end_time elapsed
    if [ $MEASURE_TIME -eq 1 ]; then
        start_time=$(date +%s.%N)
    fi

    if g++ ${flags} -o ${OUTPUT_FILE} ${src_file} 2> "$tmp_err"; then
        # 成功時でも警告があれば表示
        if [ -s "$tmp_err" ]; then
            filter_paths < "$tmp_err" >&2
        fi
        rm -f "$tmp_err"

        if [ $MEASURE_TIME -eq 1 ]; then
            end_time=$(date +%s.%N)
            elapsed=$(echo "scale=0; ($end_time - $start_time) * 1000 / 1 + 0.999" | bc | cut -d'.' -f1)
            echo "Compilation successful! (${elapsed}ms)" >&2
        else
            echo "Compilation successful!" >&2
        fi
        return 0
    else
        # 失敗時
        filter_paths < "$tmp_err" >&2
        rm -f "$tmp_err"
        echo "Compilation failed!" >&2
        return 1
    fi
}

# Parse options
while [ $# -gt 0 ]; do
    case "$1" in
        -t|--time)
            MEASURE_TIME=1
            shift
            ;;
        -s)
            if [ -n "$2" ]; then
                SOURCE_FILE="$2"
                shift 2
            else
                echo "Error: -s requires a source file argument"
                usage
            fi
            ;;
        -h|--help)
            usage
            ;;
        *)
            # 最初の引数がコマンドの場合はループを抜ける
            break
            ;;
    esac
done

# Default behavior
if [ $# -eq 0 ]; then
    if [ $MEASURE_TIME -eq 1 ]; then
        "$SCRIPT_DIR/run.sh" --time -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
    else
        "$SCRIPT_DIR/run.sh" -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
    fi
    exit 0
fi

case "$1" in
    work)
        if [ $MEASURE_TIME -eq 1 ]; then
            "$SCRIPT_DIR/run.sh" --time -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
        else
            "$SCRIPT_DIR/run.sh" -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
        fi
        ;;
    debug)
        if [ $MEASURE_TIME -eq 1 ]; then
            "$SCRIPT_DIR/gen_run.sh" --time -g "${PROJ_ROOT}/templates/testcase_generate.cpp" -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
        else
            "$SCRIPT_DIR/gen_run.sh" -g "${PROJ_ROOT}/templates/testcase_generate.cpp" -s ${SOURCE_FILE} -i ${INPUT_FILE} -o ${OUTPUT_LOG} -e ${ERROR_LOG}
        fi
        ;;
    build)
        compile ${SOURCE_FILE} || exit 1
        ;;
    run)
        compile ${SOURCE_FILE} || exit 1
        if [ $MEASURE_TIME -eq 1 ]; then
            echo "Running..." >&2
            /usr/bin/time -p "${OUTPUT_FILE}" 2>&1 | grep -E '^(real|user|sys)' | sed 's/^/  /' >&2 || "${OUTPUT_FILE}"
        else
            "${OUTPUT_FILE}"
        fi
        ;;
    test)
        compile ${SOURCE_FILE} || exit 1
        if [ $MEASURE_TIME -eq 1 ]; then
            echo "Running..." >&2
            local tmp_time=$(mktemp)
            /usr/bin/time -p "${OUTPUT_FILE}" < ${INPUT_FILE} > ${OUTPUT_LOG} 2> >(tee "$tmp_time" >&2)
            cat "$tmp_time" | grep -v "^${OUTPUT_FILE}" >> ${ERROR_LOG} 2>/dev/null || true
            rm -f "$tmp_time"
            echo "Output written to $(to_relative_path ${OUTPUT_LOG})"
            echo "Errors written to $(to_relative_path ${ERROR_LOG})"
        else
            "${OUTPUT_FILE}" < ${INPUT_FILE} > ${OUTPUT_LOG} 2> ${ERROR_LOG}
            echo "Output written to $(to_relative_path ${OUTPUT_LOG})"
            echo "Errors written to $(to_relative_path ${ERROR_LOG})"
        fi
        ;;
    interactive)
        compile ${SOURCE_FILE} || exit 1
        echo "Running in interactive mode (no buffering)..."
        if [ $MEASURE_TIME -eq 1 ]; then
            /usr/bin/time -p stdbuf -i0 -o0 -e0 "${OUTPUT_FILE}"
        else
            stdbuf -i0 -o0 -e0 "${OUTPUT_FILE}"
        fi
        ;;
    tty)
        compile ${SOURCE_FILE} || exit 1
        echo "Running in pseudo-TTY mode..."
        if [ $MEASURE_TIME -eq 1 ]; then
            /usr/bin/time -p script -q /dev/null "${OUTPUT_FILE}"
        else
            script -q /dev/null "${OUTPUT_FILE}"
        fi
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
esac
