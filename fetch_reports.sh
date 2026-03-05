#!/bin/bash

# 自动判断A股或港股，分别调用对应脚本
# Usage: ./fetch_reports.sh <公司名称或代码> [开始日期] [结束日期]

set -euo pipefail

COMPANY_KEY="${1:-}"
START_DATE_INPUT="${2:-}"
END_DATE_INPUT="${3:-}"

if [ -z "$COMPANY_KEY" ]; then
    echo "错误: 请提供公司名称或股票代码"
    echo "用法: $0 <公司名称或代码> [开始日期] [结束日期]"
    echo "示例: $0 平安银行 2024-01-01 2024-12-31"
    exit 1
fi

strip_prefix() {
    local input="$1"
    input="${input#A:}"
    input="${input#HK:}"
    input="${input#A股:}"
    input="${input#A股：}"
    input="${input#港股:}"
    input="${input#港股：}"
    echo "$input"
}

detect_market_override() {
    local input="$1"
    case "$input" in
        A:*|A股:*|A股：*)
            echo "A"
            ;;
        HK:*|港股:*|港股：*)
            echo "HK"
            ;;
        *)
            echo ""
            ;;
    esac
}

is_a_share_code() {
    local key="$1"
    local upper
    upper="$(echo "$key" | tr '[:lower:]' '[:upper:]')"
    if [[ "$upper" =~ ^(SH|SZ|BJ)[0-9]{6}$ ]]; then
        return 0
    fi
    if [[ "$key" =~ ^[0-9]{6}$ ]]; then
        return 0
    fi
    return 1
}

normalize_hk_date() {
    local input="$1"
    if [ -z "$input" ]; then
        echo ""
        return 0
    fi
    if [[ "$input" =~ ^[0-9]{2}/[0-9]{2}/[0-9]{4}$ ]]; then
        echo "$input"
        return 0
    fi
    if [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        local year month day
        IFS='-' read -r year month day <<< "$input"
        echo "${day}/${month}/${year}"
        return 0
    fi
    echo "$input"
}

MARKET_OVERRIDE="$(detect_market_override "$COMPANY_KEY")"
COMPANY_KEY="$(strip_prefix "$COMPANY_KEY")"

if [ "$MARKET_OVERRIDE" = "A" ] || is_a_share_code "$COMPANY_KEY"; then
    ./fetch_cninfo_reports.sh "$COMPANY_KEY" "$START_DATE_INPUT" "$END_DATE_INPUT"
    exit 0
fi

if [ "$MARKET_OVERRIDE" = "HK" ]; then
    START_DATE_HK="$(normalize_hk_date "$START_DATE_INPUT")"
    ./fetch_hkex_reports.sh "$COMPANY_KEY" "${START_DATE_HK:-01/01/2024}"
    exit 0
fi

# 无法明确判断时，优先尝试港股；如需A股可用前缀 A: 或 A股:
START_DATE_HK="$(normalize_hk_date "$START_DATE_INPUT")"
./fetch_hkex_reports.sh "$COMPANY_KEY" "${START_DATE_HK:-01/01/2024}"
