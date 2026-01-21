#!/bin/bash
# AtCoder C++ 23 (gcc 14.2.0) 互換のコンパイルフラグ
# ローカル環境で利用可能なフラグのみを使用

# スクリプトのディレクトリとプロジェクトルートを取得
SCRIPT_DIR_CF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT_CF="$(cd "$SCRIPT_DIR_CF/.." && pwd)"

# 基本フラグ（ローカルで使用可能なもの）
ATCODER_FLAGS=(
    "-DATCODER"
    "-DONLINE_JUDGE"
    "-DNOMINMAX"
    "-std=gnu++23"           # C++23を試す（利用不可の場合はgnu++20にフォールバック）
    "-O2"
    "-Wall"
    "-Wextra"
    "-march=native"
    "-mtune=native"
    "-pthread"
    "-I${PROJ_ROOT_CF}"
    "-I${PROJ_ROOT_CF}/lib"
    "-I${PROJ_ROOT_CF}/lib/ac-library"
    "-I/opt/homebrew/opt/boost/include"
    "-Wno-pragmas"
)

# 利用可能なC++標準を確認してフラグを設定
get_compile_flags() {
    # C++23が使えるか確認
    if g++ -std=gnu++23 -x c++ -c /dev/null -o /dev/null 2>/dev/null; then
        echo "${ATCODER_FLAGS[@]}"
    else
        # C++23が使えない場合はC++20にフォールバック
        local flags=("${ATCODER_FLAGS[@]//-std=gnu++23/-std=gnu++20}")
        echo "${flags[@]}"
    fi
}

# constexprの深さ制限（利用可能な場合のみ）
# ※ローカル環境によっては未サポートの可能性があるため、エラーを無視
EXTENDED_FLAGS=(
    "-fconstexpr-depth=2147483647"
    "-fconstexpr-loop-limit=2147483647"
    "-fconstexpr-ops-limit=4294967295"
)

# 拡張フラグが使えるか確認
get_extended_flags() {
    local flags=()
    for flag in "${EXTENDED_FLAGS[@]}"; do
        if g++ "$flag" -x c++ -c /dev/null -o /dev/null 2>/dev/null; then
            flags+=("$flag")
        fi
    done
    echo "${flags[@]}"
}

# 全フラグを取得
get_all_flags() {
    local base_flags=$(get_compile_flags)
    local ext_flags=$(get_extended_flags)
    echo "$base_flags $ext_flags"
}

# このスクリプトが直接実行された場合はフラグを出力
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    get_all_flags
fi
