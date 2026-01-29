#!/usr/bin/env bash
# gen_run.sh — テスト生成器 (generator.cpp) と解答 (solution.cpp) を一括ビルド＆実行
# AtCoder C++ 23 (gcc 14.2.0) 互換環境
#
# 使い方:
#   ./gen_run.sh -g testcase_generate.cpp -s main.cpp [options] [-- <args to solution>]
#
# 必須オプション:
#   -g, --gen <generator.cpp>   テストケースを出力する C++ ソース
#   -s, --src <solution.cpp>    解答となる C++ ソース
#
# 主な任意オプション:
#   -n, --num <N>               生成＆実行ループ回数 (既定:1)
#   -i, --input <file>          テストケースの出力先ファイル (既定: genrun_tmp_*.in)
#   -o, --out <file>            解答の標準出力をこのファイルに上書き保存
#   -e, --err <file>            生成器＋解答の標準エラーをこのファイルに上書き保存
#   -t, --tmp <prefix>          一時入力ファイルの接頭辞 (既定: genrun_tmp)
#   -h, --help                  ヘルプを表示
#   -- <args...>                そのまま解答プログラムへ渡す追加引数
#
# 動作概要:
#   1. generator.cpp をビルド → "gen" に固定
#   2. -n 回ループ:
#        • ./gen > <tmp>.in で入力生成
#        • run.sh を呼び出し解答を実行
#
# * 本スクリプトは run.sh と同じディレクトリに配置してください。

set -euo pipefail

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

# -------- デフォルト値 --------
GEN_SRC=""
SOL_SRC=""
TESTS=1
INPUT_FILE=""
OUT_FILE=""
ERR_FILE=""
TMP_PREFIX="genrun_tmp"
MEASURE_TIME=0
PROGRAM_ARGS=()   # 空配列で初期化

usage() {
  cat <<EOF
Usage: $0 -g generator.cpp -s solution.cpp [options] [-- <args to solution>]

Required:
  -g, --gen     C++ source for test generator.
  -s, --src     C++ source for solution.

Optional:
  -n, --num     Number of test iterations (default: 1).
  -i, --input   Output file for generated test case (default: genrun_tmp_*.in).
  -o, --out     Capture solution's stdout in this file (overwritten).
  -e, --err     Capture stderr (generator + solution) in this file (overwritten).
  -t, --tmp     Prefix for temporary files (default: genrun_tmp).
      --time    Measure and display execution time.
  -h, --help    Show this help.
EOF
}

# -------- オプション解析 --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--gen)
      GEN_SRC="$2"; shift 2;;
    -s|--src)
      SOL_SRC="$2"; shift 2;;
    -n|--num)
      TESTS="$2"; shift 2;;
    -i|--input)
      INPUT_FILE="$2"; shift 2;;
    -o|--out)
      OUT_FILE="$2"; shift 2;;
    -e|--err)
      ERR_FILE="$2"; shift 2;;
    -t|--tmp)
      TMP_PREFIX="$2"; shift 2;;
    --time)
      MEASURE_TIME=1; shift;;
    -h|--help)
      usage; exit 0;;
    --)
      shift; PROGRAM_ARGS=("$@" ); break;;
    *)
      echo "[gen_run.sh] Unknown option: $1" >&2
      usage; exit 1;;
  esac
done

# -------- 必須チェック --------
if [[ -z "$GEN_SRC" || -z "$SOL_SRC" ]]; then
  echo "[gen_run.sh] Error: generator and solution sources are required." >&2
  usage; exit 1
fi

# -------- ファイルの初期化 --------
[[ -n "$OUT_FILE" ]] && : > "$OUT_FILE"
[[ -n "$ERR_FILE" ]] && : > "$ERR_FILE"

# -------- ビルド: テスト生成器 --------
GEN_BIN="build/gen"

# cleanup 旧 artifacts
rm -f "$GEN_BIN" "$GEN_BIN".exe build/*.o build/*.obj build/*.dSYM 2>/dev/null || true

# AtCoder互換のコンパイルフラグを取得
COMPILE_FLAGS=$(get_all_flags)

echo "[gen_run.sh] Compiling generator: $(to_relative_path "$GEN_SRC") -> $(to_relative_path "$GEN_BIN")" >&2

local start_time end_time elapsed
if [[ $MEASURE_TIME -eq 1 ]]; then
  start_time=$(date +%s.%N)
fi

if [[ -n "$ERR_FILE" ]]; then
  g++ $COMPILE_FLAGS -o "$GEN_BIN" "$GEN_SRC" 2>> "$ERR_FILE"
else
  g++ $COMPILE_FLAGS -o "$GEN_BIN" "$GEN_SRC"
fi

if [[ $MEASURE_TIME -eq 1 ]]; then
  end_time=$(date +%s.%N)
  elapsed=$(echo "scale=0; ($end_time - $start_time) * 1000 / 1 + 0.999" | bc | cut -d'.' -f1)
  echo "[gen_run.sh] Generator compilation time: ${elapsed}ms" >&2
fi

# -------- テスト実行ループ --------
for ((i=1; i<=TESTS; ++i)); do
  # -i オプションが指定されていればそれを使用、なければデフォルトの一時ファイル名
  if [[ -n "$INPUT_FILE" ]]; then
    IN_FILE="$INPUT_FILE"
  else
    IN_FILE="${TMP_PREFIX}_${i}.in"
  fi

  echo "[gen_run.sh] Generating test #$i -> $(to_relative_path "$IN_FILE")" >&2

  if [[ -n "$ERR_FILE" ]]; then
    ./$GEN_BIN > "$IN_FILE" 2>> "$ERR_FILE"
  else
    ./$GEN_BIN > "$IN_FILE"
  fi

  # run.sh を呼び出して解答を実行
  echo "[gen_run.sh] Running solution on test #$i" >&2

  RUNSH_ARGS=( -s "$SOL_SRC" -i "$IN_FILE" )
  [[ $MEASURE_TIME -eq 1 ]] && RUNSH_ARGS+=( --time )
  [[ -n "$OUT_FILE" ]] && RUNSH_ARGS+=( -o "$OUT_FILE" )
  [[ -n "$ERR_FILE" ]] && RUNSH_ARGS+=( -e "$ERR_FILE" )
  if (( ${#PROGRAM_ARGS[@]} > 0 )); then
    RUNSH_ARGS+=( -- "${PROGRAM_ARGS[@]}" )
  fi

  "$SCRIPT_DIR/run.sh" "${RUNSH_ARGS[@]}"

  echo "[gen_run.sh] Test #$i finished" >&2
  echo "-------------------------------------" >&2

  # 残したくない場合は下行のコメントを外す
  # rm -f "$IN_FILE"
done

echo "[gen_run.sh] All tests completed." >&2
