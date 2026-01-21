#!/bin/bash
# Interactive runner: main.cpp <-> interactive_judge.cpp
# - solution stdout -> (tee aout.txt) -> judge stdin
# - judge stdout -> solution stdin
# Logs:
#   aout.txt : solution stdout (what you "output" in interactive)
#   aerr.log : solution/judge stderr
# Usage:
#   ./interactive.sh       : run once
#   ./interactive.sh -n 30 : run 30 cases, save logs to tmp/

set -euo pipefail

# Parse options
NUM_CASES=1
while getopts "n:" opt; do
  case $opt in
    n) NUM_CASES="$OPTARG" ;;
    *) echo "Usage: $0 [-n num_cases]" >&2; exit 1 ;;
  esac
done

# compile_flags.sh から共通フラグ読み込み
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

# Defaults
SOL_SRC="main.cpp"
JUDGE_SRC="templates/interactive_judge.cpp"
SOL_BIN="build/a.out"
JUDGE_BIN="build/judge.out"

# Create tmp directory if needed
mkdir -p tmp

compile() {
  local src="$1"
  local out="$2"
  echo "Compiling $(to_relative_path "${src}") -> $(to_relative_path "${out}") ..."
  local flags
  flags="$(get_all_flags)"
  if ! g++ ${flags} -o "${out}" "${src}" 2>&1 | filter_paths >&2; then
    echo "Compilation failed!" >&2
    exit 1
  fi
  echo "OK"
}

run_single_case() {
  local case_num="$1"
  local out_log="$2"
  local err_log="$3"

  # FIFO 作成（テンポラリ内）
  local tmpdir_run="$(mktemp -d)"
  local sol2judge="${tmpdir_run}/sol2judge.fifo"
  local judge2sol="${tmpdir_run}/judge2sol.fifo"
  mkfifo "${sol2judge}" "${judge2sol}"

  local judge_in_log="tmp/interactive_${case_num}_judge_to_sol.log"
  local sol_out_log="tmp/interactive_${case_num}_sol_to_judge.log"
  local timeline_log="${tmpdir_run}/timeline.log"

  # Logs reset
  : > "${out_log}"
  : > "${err_log}"
  : > "${judge_in_log}"
  : > "${sol_out_log}"
  : > "${timeline_log}"

  # 時系列ログ用スクリプト
  local log_wrapper="${tmpdir_run}/log_wrapper.sh"
  cat > "${log_wrapper}" << 'WRAPPER_EOF'
#!/bin/bash
direction="$1"
logfile="$2"
while IFS= read -r line; do
  printf "%s\t%s\t%s\n" "$(date +%s.%N)" "$direction" "$line" >> "$logfile"
  echo "$line"
done
WRAPPER_EOF
  chmod +x "${log_wrapper}"

  # 1) judge を先に起動
  {
    stdbuf -i0 -o0 -e0 "./${JUDGE_BIN}" \
      < "${sol2judge}" \
      2>> "${err_log}"
  } | "${log_wrapper}" "J->S" "${timeline_log}" | tee -a "${judge_in_log}" > "${judge2sol}" &
  local judge_pid=$!

  # 2) solution を起動
  {
    stdbuf -i0 -o0 -e0 "./${SOL_BIN}" \
      < "${judge2sol}" \
      2>> "${err_log}"
  } | "${log_wrapper}" "S->J" "${timeline_log}" | tee -a "${sol_out_log}" > "${sol2judge}"

  # solution が終わったら judge も待つ
  wait "${judge_pid}" 2>/dev/null || true

  # 対話記録を時系列順に統合
  echo "=== Interactive Session Log (Timeline) - Case ${case_num} ===" > "${out_log}"
  echo "" >> "${out_log}"

  if [ -s "${timeline_log}" ]; then
    sort -n "${timeline_log}" | while IFS=$'\t' read -r timestamp direction line; do
      printf "%-5s %s\n" "$direction" "$line"
    done >> "${out_log}"
  fi
  echo "" >> "${out_log}"

  # Cleanup
  rm -rf "${tmpdir_run}"
}

# Build
compile "${SOL_SRC}"   "${SOL_BIN}"
compile "${JUDGE_SRC}" "${JUDGE_BIN}"

if [ "${NUM_CASES}" -eq 1 ]; then
  # Single case mode - use original filenames
  OUT_LOG="aout.txt"
  ERR_LOG="aerr.log"

  echo "Running interactive: $(to_relative_path "${SOL_BIN}") <-> $(to_relative_path "${JUDGE_BIN}")"
  echo "  interaction log  -> ${OUT_LOG}"
  echo "  stderr (both)    -> ${ERR_LOG}"
  echo ""

  run_single_case "1" "${OUT_LOG}" "${ERR_LOG}"

  echo ""
  echo "Done."
  echo "Output: ${OUT_LOG}"
  echo "Error : ${ERR_LOG}"
else
  # Multiple cases mode
  echo "Running ${NUM_CASES} interactive test cases..."
  echo ""

  pass_count=0
  fail_count=0

  for i in $(seq 1 "${NUM_CASES}"); do
    out_log="tmp/interactive_${i}.txt"
    err_log="tmp/interactive_${i}.err"

    printf "[%3d/%3d] Running case %d... " "$i" "${NUM_CASES}" "$i"

    run_single_case "$i" "${out_log}" "${err_log}"

    # Check if the case passed (look for "Correct!" in the log)
    if grep -q "Correct!" "${out_log}" 2>/dev/null; then
      echo "✓ PASS"
      ((pass_count++))
    else
      echo "✗ FAIL"
      ((fail_count++))
    fi
  done

  echo ""
  echo "===================================="
  echo "Results: ${pass_count} / ${NUM_CASES} passed"
  if [ "${fail_count}" -gt 0 ]; then
    echo "Failed cases: ${fail_count}"
  fi
  echo "Logs saved to tmp/interactive_*.txt"
  echo "===================================="

  # Clean up non-.txt log files
  rm -f tmp/interactive_*.err tmp/interactive_*_judge_to_sol.log tmp/interactive_*_sol_to_judge.log 2>/dev/null || true
fi
