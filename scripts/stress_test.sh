#!/bin/bash
# stress_test.sh - ストレステスト：main.cpp と main_greedy.cpp の出力を比較
# AtCoder C++ 23 (gcc 14.2.0) 互換環境

set -uo pipefail

# compile_flags.shから共通フラグを読み込む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/compile_flags.sh"

# 絶対パスを相対パスに変換する関数
to_relative_path() {
    local path="$1"
    echo "${path#$PROJ_ROOT/}"
}

# エラーメッセージ内の絶対パスを相対パスに変換
filter_paths() {
    sed "s|$PROJ_ROOT/||g"
}

# デフォルト設定
GENERATOR="templates/testcase_generate.cpp"
MAIN_SOLUTION="main.cpp"
GREEDY_SOLUTION="templates/main_greedy.cpp"
NUM_TESTS=100
OUTPUT_FILE="aout.txt"
TMP_DIR="tmp"

# 使用方法
usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -g <file>   Generator source (default: testcase_generate.cpp)
  -m <file>   Main solution source (default: main.cpp)
  -r <file>   Reference/Greedy solution source (default: main_greedy.cpp)
  -n <num>    Number of tests (default: 100)
  -o <file>   Output file (default: aout.txt)
  -h          Show this help

EOF
}

# オプション解析
while [[ $# -gt 0 ]]; do
  case "$1" in
    -g) GENERATOR="$2"; shift 2;;
    -m) MAIN_SOLUTION="$2"; shift 2;;
    -r) GREEDY_SOLUTION="$2"; shift 2;;
    -n) NUM_TESTS="$2"; shift 2;;
    -o) OUTPUT_FILE="$2"; shift 2;;
    -h) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage; exit 1;;
  esac
done

# 一時ディレクトリ作成
mkdir -p "$TMP_DIR"

# 出力ファイルを初期化
: > "$OUTPUT_FILE"

# バイナリ名
GEN_BIN="$TMP_DIR/gen"
MAIN_BIN="$TMP_DIR/main"
GREEDY_BIN="$TMP_DIR/greedy"

# コンパイル
echo "=== コンパイル中 ===" | tee -a "$OUTPUT_FILE"
echo "Generator: $(to_relative_path "$GENERATOR")" | tee -a "$OUTPUT_FILE"
echo "Main solution: $(to_relative_path "$MAIN_SOLUTION")" | tee -a "$OUTPUT_FILE"
echo "Greedy solution: $(to_relative_path "$GREEDY_SOLUTION")" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# AtCoder互換のコンパイルフラグを取得
COMPILE_FLAGS=$(get_all_flags)

# Generator をコンパイル
echo "[1/3] Compiling generator..." | tee -a "$OUTPUT_FILE"
if ! g++ $COMPILE_FLAGS -o "$GEN_BIN" "$GENERATOR" 2>&1 | filter_paths | tee -a "$OUTPUT_FILE"; then
  echo "Error: Failed to compile generator" | tee -a "$OUTPUT_FILE"
  exit 1
fi

# Main solution をコンパイル
echo "[2/3] Compiling main solution..." | tee -a "$OUTPUT_FILE"
if ! g++ $COMPILE_FLAGS -o "$MAIN_BIN" "$MAIN_SOLUTION" 2>&1 | filter_paths | tee -a "$OUTPUT_FILE"; then
  echo "Error: Failed to compile main solution" | tee -a "$OUTPUT_FILE"
  exit 1
fi

# Greedy solution をコンパイル
echo "[3/3] Compiling greedy solution..." | tee -a "$OUTPUT_FILE"
if ! g++ $COMPILE_FLAGS -o "$GREEDY_BIN" "$GREEDY_SOLUTION" 2>&1 | filter_paths | tee -a "$OUTPUT_FILE"; then
  echo "Error: Failed to compile greedy solution" | tee -a "$OUTPUT_FILE"
  exit 1
fi

echo "" | tee -a "$OUTPUT_FILE"
echo "=== テスト実行中 ($NUM_TESTS cases) ===" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 統計カウンタ
AC_COUNT=0
WA_COUNT=0
declare -a FAILED_CASES=()

# テストループ
for ((i=1; i<=NUM_TESTS; i++)); do
  # テストケース生成
  INPUT_FILE="$TMP_DIR/test_$i.in"
  MAIN_OUT="$TMP_DIR/main_$i.out"
  GREEDY_OUT="$TMP_DIR/greedy_$i.out"

  "$GEN_BIN" > "$INPUT_FILE" 2>/dev/null

  # Main solution 実行
  "$MAIN_BIN" < "$INPUT_FILE" > "$MAIN_OUT" 2>/dev/null

  # Greedy solution 実行
  "$GREEDY_BIN" < "$INPUT_FILE" > "$GREEDY_OUT" 2>/dev/null

  # 出力を比較
  if diff -q "$MAIN_OUT" "$GREEDY_OUT" > /dev/null 2>&1; then
    ((AC_COUNT++))
    echo -ne "\rProgress: $i/$NUM_TESTS (AC: $AC_COUNT, WA: $WA_COUNT)"
  else
    ((WA_COUNT++))
    FAILED_CASES+=("$i")
    echo -ne "\rProgress: $i/$NUM_TESTS (AC: $AC_COUNT, WA: $WA_COUNT) [WA detected!]"
  fi
done

echo ""
echo ""

# 結果サマリー
echo "=== テスト結果 ===" | tee -a "$OUTPUT_FILE"
echo "Total tests: $NUM_TESTS" | tee -a "$OUTPUT_FILE"
echo "AC: $AC_COUNT" | tee -a "$OUTPUT_FILE"
echo "WA: $WA_COUNT" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# WA があった場合、詳細を出力
if [[ $WA_COUNT -gt 0 ]]; then
  echo "=== WA Cases Details ===" | tee -a "$OUTPUT_FILE"
  echo "" | tee -a "$OUTPUT_FILE"

  for case_num in "${FAILED_CASES[@]}"; do
    INPUT_FILE="$TMP_DIR/test_$case_num.in"
    MAIN_OUT="$TMP_DIR/main_$case_num.out"
    GREEDY_OUT="$TMP_DIR/greedy_$case_num.out"

    echo "----------------------------------------" | tee -a "$OUTPUT_FILE"
    echo "Test Case $case_num" | tee -a "$OUTPUT_FILE"
    echo "----------------------------------------" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"

    echo "[Input]" | tee -a "$OUTPUT_FILE"
    cat "$INPUT_FILE" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"

    echo "[Your Answer]" | tee -a "$OUTPUT_FILE"
    cat "$MAIN_OUT" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"

    echo "[Greedy Answer]" | tee -a "$OUTPUT_FILE"
    cat "$GREEDY_OUT" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"

    # echo "[Diff]" | tee -a "$OUTPUT_FILE"
    # diff -u "$GREEDY_OUT" "$MAIN_OUT" | tee -a "$OUTPUT_FILE" || true
    # echo "" | tee -a "$OUTPUT_FILE"
  done
else
  echo "All tests passed! No differences found." | tee -a "$OUTPUT_FILE"
fi

# echo "=== ストレステスト完了 ===" | tee -a "$OUTPUT_FILE"
# echo "結果は $OUTPUT_FILE に保存されました。" | tee -a "$OUTPUT_FILE"

# クリーンアップオプション（コメントアウト: 必要に応じて有効化）
# Note: tmp/ディレクトリの内容のみクリア（ディレクトリ自体は残す）
# rm -rf "$TMP_DIR"/*

exit 0
