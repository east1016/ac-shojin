#!/usr/bin/env bash
# run.sh — compile and execute C++ solutions with flexible I/O redirection
# AtCoder C++ 23 (gcc 14.2.0) 互換環境
#
# 🆕 2025‑11‑20 更新 (rev‑6)
#   • AtCoder環境に合わせたコンパイルフラグ
#   • デフォルトファイル名をMain.cppに変更
#   • 出力バイナリ名をa.outに変更
#   • out/err ファイルを最優先で truncate
#   • cleanup を強化 : 以前のバイナリ / *.o / *.dSYM* を完全削除
#   • コンパイル失敗時は即終了（実行パートへ進まない）
#
# 使い方（例）:
#   ./run.sh -s main.cpp                          # 標準 I/O はターミナルへ
#   ./run.sh -s main.cpp -i ain.txt -o aout.txt   # 入出力をファイルに
#   ./run.sh -s main.cpp -e aerr.log              # すべてのエラーを aerr.log へ
#   ./run.sh -s main.cpp -- 100 200               # 実行ファイルに追加引数を渡す
#
# オプション一覧:
#   -s|--source <file.cpp>   コンパイルするソース (必須)
#   -i|--in     <file>       標準入力に使うファイル
#   -o|--out    <file>       標準出力をリダイレクト
#   -e|--err    <file>       標準エラー（コンパイル & 実行）をリダイレクト
#   -t|--target <name>       出力バイナリ名 (既定: out)
#   -h|--help                このヘルプを表示
#   --                       以降は実行ファイルへそのまま渡す引数

set -uo pipefail  # "-e" は自前でハンドリングする

# 空配列を宣言 ("set -u" 対策)
declare -a PROGRAM_ARGS=()

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

SRC=""
IN_FILE=""
OUT_FILE=""
ERR_FILE=""
TARGET="${PROJ_ROOT}/build/a.out"
MEASURE_TIME=0

usage() {
  cat <<EOF
Usage: $0 -s <source.cpp> [options] [-- <program args>]

Required:
  -s, --source   C++ source file to compile.

Optional:
  -i, --in       File to feed to standard input.
  -o, --out      Redirect standard output to this file.
  -e, --err      Redirect standard error (compile & run) to this file.
  -t, --target   Output binary name (default: build/a.out).
      --time     Measure and display execution time.
  -h, --help     Show this help.

Anything after '--' is passed to the compiled program.
EOF
}

# --- オプション解析 ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source)
      SRC="$2"; shift 2 ;;
    -i|--in)
      IN_FILE="$2"; shift 2 ;;
    -o|--out)
      OUT_FILE="$2"; shift 2 ;;
    -e|--err)
      ERR_FILE="$2"; shift 2 ;;
    -t|--target)
      TARGET="$2"; shift 2 ;;
    --time)
      MEASURE_TIME=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    --)
      shift
      PROGRAM_ARGS=("$@")
      break ;;
    *)
      echo "[run.sh] Unknown option: $1" >&2
      usage
      exit 1 ;;
  esac
done

# --- 必須チェック ---
if [[ -z "$SRC" ]]; then
  echo "[run.sh] Error: source file is required." >&2
  usage
  exit 1
fi

# --- out/err ファイルを最優先で空にする ---
[[ -n "$OUT_FILE" ]] && : > "$OUT_FILE"
[[ -n "$ERR_FILE" ]] && : > "$ERR_FILE"

# --- cleanup ステップ: 既存アーティファクトを完全削除 ---
cleanup() {
  echo "[run.sh] Cleaning previous artifacts" >&2
  rm -f "$TARGET" build/out build/a.out build/*.o build/*.obj build/*.exe 2>/dev/null || true
  rm -rf "$TARGET.dSYM" build/out.dSYM build/a.out.dSYM build/*.dSYM 2>/dev/null || true
}
cleanup

# AtCoder互換のコンパイルフラグを取得
COMPILE_FLAGS=$(get_all_flags)

# --- コンパイル ---
compile() {
  local rel_src=$(to_relative_path "$SRC")
  local rel_target=$(to_relative_path "$TARGET")
  echo "[run.sh] Compiling $rel_src -> $rel_target" >&2
  local compile_cmd=(g++ $COMPILE_FLAGS -o "$TARGET" "$SRC")

  local start_time end_time elapsed
  if [[ $MEASURE_TIME -eq 1 ]]; then
    start_time=$(date +%s.%N)
  fi

  if [[ -n "$ERR_FILE" ]]; then
    # 一時ファイルにコンパイル結果を保存
    local tmp_compile_err=$(mktemp)

    if ! "${compile_cmd[@]}" 2> "$tmp_compile_err"; then
      echo "[run.sh] Compilation failed." >&2
      # errorのみをターミナルとERR_FILEに出力（warningは灰色で表示）
      echo "--- Errors ---" >&2
      grep "error:" "$tmp_compile_err" | filter_paths | GREP_COLORS='mt=01;31' grep --color=always "error:" >&2
      echo "" >&2
      echo "--- Warnings (hidden from aerr.log) ---" | GREP_COLORS='mt=00;90' grep --color=always ".*" >&2
      grep "warning:" "$tmp_compile_err" | filter_paths | GREP_COLORS='mt=00;90' grep --color=always ".*" >&2
      # ERR_FILEにはerrorのみを色付きで出力（ANSIカラーコード付き）
      echo -e "\033[1;31m=== Compilation Errors ===\033[0m" > "$ERR_FILE"
      grep "error:" "$tmp_compile_err" | filter_paths | sed 's/error:/\x1b[1;31merror:\x1b[0m/g' >> "$ERR_FILE"
      rm -f "$tmp_compile_err"
      exit 1
    fi
    rm -f "$tmp_compile_err"
    # コンパイル成功時はERR_FILEを空にして実行時エラーのみを記録
    : > "$ERR_FILE"
  else
    if ! "${compile_cmd[@]}" ; then
      echo "[run.sh] Compilation failed." >&2
      exit 1
    fi
  fi

  if [[ $MEASURE_TIME -eq 1 ]]; then
    end_time=$(date +%s.%N)
    elapsed=$(echo "scale=0; ($end_time - $start_time) * 1000 / 1 + 0.999" | bc | cut -d'.' -f1)
    echo "[run.sh] Compilation time: ${elapsed}ms" >&2
  fi
}
compile

# --- 実行コマンド構築 ---
cmd=("$TARGET")
if (( ${#PROGRAM_ARGS[@]} )); then
  cmd+=("${PROGRAM_ARGS[@]}")
fi

echo "[run.sh] Running $(to_relative_path "$TARGET")" >&2

# --- I/O リダイレクション ---
run_program() {
  local exit_code=0
  local start_time end_time elapsed

  if [[ $MEASURE_TIME -eq 1 ]]; then
    start_time=$(date +%s.%N)
  fi

  if [[ -n "$IN_FILE" ]]; then
    if [[ -n "$OUT_FILE" ]]; then
      if [[ -n "$ERR_FILE" ]]; then
        "${cmd[@]}" < "$IN_FILE" > "$OUT_FILE" 2>> "$ERR_FILE" || exit_code=$?
      else
        "${cmd[@]}" < "$IN_FILE" > "$OUT_FILE" || exit_code=$?
      fi
    else
      if [[ -n "$ERR_FILE" ]]; then
        "${cmd[@]}" < "$IN_FILE" 2>> "$ERR_FILE" || exit_code=$?
      else
        "${cmd[@]}" < "$IN_FILE" || exit_code=$?
      fi
    fi
  else
    if [[ -n "$OUT_FILE" ]]; then
      if [[ -n "$ERR_FILE" ]]; then
        "${cmd[@]}" > "$OUT_FILE" 2>> "$ERR_FILE" || exit_code=$?
      else
        "${cmd[@]}" > "$OUT_FILE" || exit_code=$?
      fi
    else
      if [[ -n "$ERR_FILE" ]]; then
        "${cmd[@]}" 2>> "$ERR_FILE" || exit_code=$?
      else
        "${cmd[@]}" || exit_code=$?
      fi
    fi
  fi

  if [[ $MEASURE_TIME -eq 1 ]]; then
    end_time=$(date +%s.%N)
    elapsed=$(echo "scale=0; ($end_time - $start_time) * 1000 / 1 + 0.999" | bc | cut -d'.' -f1)
    echo "[run.sh] Execution time: ${elapsed}ms" >&2
  fi

  # 実行時エラーをERR_FILEに記録
  if [[ $exit_code -ne 0 ]]; then
    local error_msg=""
    case $exit_code in
      139|133) error_msg="Segmentation fault (core dumped)" ;;  # 139: Linux, 133: macOS
      134|132) error_msg="Aborted (core dumped)" ;;             # 134: Linux, 132: macOS
      136|135) error_msg="Floating point exception" ;;          # 136: Linux, 135: macOS
      *)       error_msg="Runtime error (exit code: $exit_code)" ;;
    esac

    if [[ -n "$ERR_FILE" ]]; then
      echo "" >> "$ERR_FILE"
      # 実行時エラーを赤色でERR_FILEに出力（ANSIカラーコード付き）
      echo -e "\033[1;31m[run.sh] $error_msg\033[0m" >> "$ERR_FILE"
    fi
    echo -e "\033[1;31m[run.sh] $error_msg\033[0m" >&2
  fi

  return $exit_code
}
run_program

echo "[run.sh] Done." >&2
