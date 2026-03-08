#!/bin/bash

# 自动判断A股或港股，分别调用对应脚本
# Usage: ./fetch_reports.sh <公司名称或代码> [开始日期] [结束日期] [--download] [--download-dir DIR]

set -euo pipefail

DOWNLOAD_PDF="${DOWNLOAD_PDF:-0}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-./downloads}"

POSITIONAL_ARGS=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --download)
            DOWNLOAD_PDF=1
            shift
            ;;
        --download-dir)
            if [ "$#" -lt 2 ]; then
                echo "错误: --download-dir 需要参数"
                exit 1
            fi
            DOWNLOAD_PDF=1
            DOWNLOAD_DIR="$2"
            shift 2
            ;;
        --download-dir=*)
            DOWNLOAD_PDF=1
            DOWNLOAD_DIR="${1#*=}"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ "$#" -gt 0 ]; then
    POSITIONAL_ARGS+=("$@")
fi

set -- "${POSITIONAL_ARGS[@]}"

COMPANY_KEY="${1:-}"
START_DATE_INPUT="${2:-}"
END_DATE_INPUT="${3:-}"

if [ -z "$COMPANY_KEY" ]; then
    echo "错误: 请提供公司名称或股票代码"
    echo "用法: $0 <公司名称或代码> [开始日期] [结束日期] [--download] [--download-dir DIR]"
    echo "示例: $0 平安银行 2024-01-01 2024-12-31 --download"
    exit 1
fi

if [ "$DOWNLOAD_PDF" = "1" ] && [ -z "$DOWNLOAD_DIR" ]; then
    echo "错误: --download-dir 不能为空"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$MARKET_OVERRIDE" = "A" ] || is_a_share_code "$COMPANY_KEY"; then
    if [ "$DOWNLOAD_PDF" = "1" ]; then
        "$SCRIPT_DIR/fetch_cninfo_reports.sh" "$COMPANY_KEY" "$START_DATE_INPUT" "$END_DATE_INPUT" --download --download-dir "$DOWNLOAD_DIR"
    else
        "$SCRIPT_DIR/fetch_cninfo_reports.sh" "$COMPANY_KEY" "$START_DATE_INPUT" "$END_DATE_INPUT"
    fi
    exit 0
fi

if [ "$MARKET_OVERRIDE" = "HK" ]; then
    START_DATE_HK="$(normalize_hk_date "$START_DATE_INPUT")"
    END_DATE_HK="$(normalize_hk_date "$END_DATE_INPUT")"
    if [ "$DOWNLOAD_PDF" = "1" ]; then
        "$SCRIPT_DIR/fetch_hkex_reports.sh" "$COMPANY_KEY" "${START_DATE_HK:-01/01/2024}" "$END_DATE_HK" --download --download-dir "$DOWNLOAD_DIR"
    else
        "$SCRIPT_DIR/fetch_hkex_reports.sh" "$COMPANY_KEY" "${START_DATE_HK:-01/01/2024}" "$END_DATE_HK"
    fi
    exit 0
fi

# 无法明确判断时，优先尝试港股；如需A股可用前缀 A: 或 A股:
START_DATE_HK="$(normalize_hk_date "$START_DATE_INPUT")"
END_DATE_HK="$(normalize_hk_date "$END_DATE_INPUT")"
if [ "$DOWNLOAD_PDF" = "1" ]; then
    "$SCRIPT_DIR/fetch_hkex_reports.sh" "$COMPANY_KEY" "${START_DATE_HK:-01/01/2024}" "$END_DATE_HK" --download --download-dir "$DOWNLOAD_DIR"
else
    "$SCRIPT_DIR/fetch_hkex_reports.sh" "$COMPANY_KEY" "${START_DATE_HK:-01/01/2024}" "$END_DATE_HK"
fi
