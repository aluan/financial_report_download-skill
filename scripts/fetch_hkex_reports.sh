#!/bin/bash

# 从披露易平台获取香港上市公司财报
# Usage: ./fetch_hkex_reports.sh <公司名称> [开始日期] [结束日期] [--download] [--download-dir DIR]

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

COMPANY_NAME_TRADITIONAL="${1:-}"
START_DATE_INPUT="${2:-}"
END_DATE_INPUT="${3:-}"

if [ -z "$COMPANY_NAME_TRADITIONAL" ]; then
    echo "错误: 请提供公司名称"
    echo "用法: $0 <公司名称> [开始日期] [结束日期] [--download] [--download-dir DIR]"
    echo "示例: $0 海底捞 01/01/2025 12/31/2025 --download"
    exit 1
fi

if [ "$DOWNLOAD_PDF" = "1" ] && [ -z "$DOWNLOAD_DIR" ]; then
    echo "错误: --download-dir 不能为空"
    exit 1
fi

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

normalize_to_iso() {
    local input="$1"
    if [ -z "$input" ]; then
        echo ""
        return 0
    fi
    if [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "$input"
        return 0
    fi
    if [[ "$input" =~ ^[0-9]{2}/[0-9]{2}/[0-9]{4}$ ]]; then
        local day month year
        IFS='/' read -r day month year <<< "$input"
        echo "${year}-${month}-${day}"
        return 0
    fi
    echo ""
}

START_DATE="$(normalize_hk_date "${START_DATE_INPUT:-01/01/2024}")"
END_DATE="$(normalize_hk_date "${END_DATE_INPUT:-}")"
START_DATE_ISO="$(normalize_to_iso "$START_DATE")"
END_DATE_ISO="$(normalize_to_iso "$END_DATE")"

# 说明：简繁转换由上层调用方（skill/模型）处理，脚本直接使用输入

echo "正在搜索 ${COMPANY_NAME_TRADITIONAL} 的财报..."
echo "开始日期: ${START_DATE}"
if [ -n "$END_DATE" ]; then
  echo "结束日期: ${END_DATE}"
fi
echo ""

# 1. 打开披露易中文网站
echo "步骤 1/7: 打开披露易网站..."
agent-browser --headed open https://www.hkexnews.hk/index_c.htm
agent-browser --headed wait --load networkidle

# 2. 输入公司名称
echo "步骤 2/7: 输入公司名称..."
agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt
STOCK_INPUT_REF=$(grep "股份代號/股份名稱" /tmp/hkex_snapshot.txt | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
agent-browser --headed fill "$STOCK_INPUT_REF" "$COMPANY_NAME_TRADITIONAL"
agent-browser --headed wait 2000

# 3. 选择标题类别
echo "步骤 3/7: 选择标题类别..."
agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt
CATEGORY_REF=$(grep "link \"所有\"" /tmp/hkex_snapshot.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
agent-browser --headed click "$CATEGORY_REF"
agent-browser --headed wait 1000

# 4. 选择"標題類別"
echo "步骤 4/8: 选择標題類別..."
agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt
TITLE_CATEGORY_REF=$(grep "標題類別" /tmp/hkex_snapshot.txt | grep "link" | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
agent-browser --headed click "$TITLE_CATEGORY_REF"
agent-browser --headed wait 1000

# 4.5. 点击"所有"下拉列表
echo "步骤 5/8: 展开标题类别下拉列表..."
agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt
ALL_DROPDOWN_REF=$(grep "link \"所有\"" /tmp/hkex_snapshot.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
agent-browser --headed click "$ALL_DROPDOWN_REF"
agent-browser --headed wait 1000

# 5. 选择"財務報表/環境、社會及管治資料"
echo "步骤 6/8: 选择财务报表类别..."
agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt
FINANCIAL_REF=$(grep "財務報表/環境、社會及管治資料" /tmp/hkex_snapshot.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
agent-browser --headed click "$FINANCIAL_REF"
agent-browser --headed wait 1000

# 6. 在子分类中选择"所有"
echo "步骤 7/8: 选择所有子分类..."
agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt
ALL_SUBCATEGORY_REF=$(grep "link \"所有\"" /tmp/hkex_snapshot.txt | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p' | sed -n '3p')
agent-browser --headed click "$ALL_SUBCATEGORY_REF"
agent-browser --headed wait 1000

pick_date() {
  local label_regex="$1"
  local date_value="$2"

  if [ -z "$date_value" ]; then
    return 0
  fi

  agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt
  local ref
  ref=$(grep -E "$label_regex" /tmp/hkex_snapshot.txt | grep "textbox" | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p' || true)
  if [ -z "$ref" ]; then
    echo "警告: 未找到日期输入框 (${label_regex})，跳过设置 ${date_value}"
    return 0
  fi

  agent-browser --headed click "$ref"
  agent-browser --headed wait 1000

  local day month year
  day=$(echo "$date_value" | cut -d'/' -f1)
  month=$(echo "$date_value" | cut -d'/' -f2)
  year=$(echo "$date_value" | cut -d'/' -f3)

  agent-browser --headed snapshot -i > /tmp/hkex_date_picker.txt
  local year_ref
  year_ref=$(grep "button \"$year\"" /tmp/hkex_date_picker.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p' || true)
  if [ -n "$year_ref" ]; then
    agent-browser --headed click "$year_ref"
    agent-browser --headed wait 500
  fi

  agent-browser --headed snapshot -i > /tmp/hkex_date_picker.txt
  local month_ref
  month_ref=$(grep "button \"$month\"" /tmp/hkex_date_picker.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p' || true)
  if [ -n "$month_ref" ]; then
    agent-browser --headed click "$month_ref"
    agent-browser --headed wait 500
  fi

  agent-browser --headed snapshot -i > /tmp/hkex_date_picker.txt
  local day_ref
  day_ref=$(grep "button \"$day\"" /tmp/hkex_date_picker.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p' || true)
  if [ -n "$day_ref" ]; then
    agent-browser --headed click "$day_ref"
    agent-browser --headed wait 500
  fi

  agent-browser --headed eval 'document.body.click()'
  agent-browser --headed wait 500
}

# 7. 选择开始/结束日期
echo "步骤 7/9: 选择开始日期..."
pick_date "開始日期|开始日期" "$START_DATE"

if [ -n "$END_DATE" ]; then
  echo "步骤 7/9: 选择结束日期..."
  pick_date "結束日期|结束日期" "$END_DATE"
fi

# 8. 点击搜索按钮
echo "步骤 8/9: 点击搜索按钮..."
# 使用 class 包含 container-title-search 的容器，减少对具体类名结构的依赖
agent-browser --headed eval --stdin <<'EVALEOF'
const container = document.querySelector('div[class*="container-title-search"]');
if (!container) throw new Error('未找到公告查询表单容器');
const btn = Array.from(container.querySelectorAll('button, a, input'))
  .find(el => {
    const text = (el.textContent || el.value || '').trim();
    const type = (el.getAttribute('type') || '').toLowerCase();
    return text === '搜尋' || type === 'submit';
  });
if (!btn) throw new Error('未找到表单內的搜尋按钮');
btn.click();
EVALEOF
agent-browser --headed wait --load networkidle
agent-browser --headed wait 2000

# 9. 提取年报和中期报告链接
echo ""
echo "步骤 9/9: 正在提取财报链接..."
TMP_JSON="$(mktemp /tmp/hkex_reports.XXXXXX.json)"
trap 'rm -f "$TMP_JSON"' EXIT

agent-browser --headed eval --stdin <<'EVALEOF' > "$TMP_JSON"
const links = Array.from(document.querySelectorAll('a')).filter(a => {
  const text = a.textContent.trim();
  const href = a.href || '';
  // 查找包含年报或中期报告的链接，且URL包含实际文件路径
  return (text.includes('年報') || text.includes('中期報告')) &&
         (href.includes('.pdf') || href.includes('listedco') || href.includes('listconews'));
});

const results = links.slice(0, 10).map(link => ({
  name: link.textContent.trim(),
  url: link.href
}));

JSON.stringify(results);
EVALEOF

cat "$TMP_JSON" | python3 -m json.tool

sanitize_filename() {
    echo "$1" | sed -e 's/[\\/:*?"<>|]/_/g' -e 's/[[:space:]]\+/ /g' -e 's/^ *//; s/ *$//' -e 's/ /_/g' | cut -c1-150
}

download_pdfs() {
    local json_file="$1"
    local out_dir="$2"

    if ! command -v curl >/dev/null 2>&1; then
        echo "错误: 未找到 curl，无法下载 PDF"
        return 1
    fi

    mkdir -p "$out_dir"

    python3 - "$json_file" "$START_DATE_ISO" "$END_DATE_ISO" <<'PY' | while IFS=$'\t' read -r idx name url; do
import json
import sys
import re

path = sys.argv[1]
start = sys.argv[2] if len(sys.argv) > 2 else ""
end = sys.argv[3] if len(sys.argv) > 3 else ""
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

if isinstance(data, str):
    try:
        data = json.loads(data)
    except json.JSONDecodeError:
        data = []

def extract_date(url):
    m = re.search(r"/((?:19|20)\d{2})/(\d{2})(\d{2})/", url)
    if not m:
        return None
    return f"{m.group(1)}-{m.group(2)}-{m.group(3)}"

def in_range(date_str):
    if not (start or end):
        return True
    if not date_str:
        return False
    if start and date_str < start:
        return False
    if end and date_str > end:
        return False
    return True

for i, item in enumerate(data, 1):
    name = (item.get('name') or 'report').strip()
    url = (item.get('url') or '').strip()
    if not url:
        continue
    date_str = extract_date(url)
    if not in_range(date_str):
        continue
    print(f"{i}\t{name}\t{url}")
PY
        if [ -z "$idx" ] || [ -z "$url" ]; then
            continue
        fi
        safe_name="$(sanitize_filename "$name")"
        if [ -z "$safe_name" ]; then
            safe_name="report"
        fi
        output_path="${out_dir}/${idx}_${safe_name}.pdf"
        echo "下载: ${output_path}"
        curl -L --fail --retry 3 -H 'User-Agent: Mozilla/5.0' -o "$output_path" "$url"
    done
}

if [ "$DOWNLOAD_PDF" = "1" ]; then
    echo ""
    echo "开始下载 PDF 到: ${DOWNLOAD_DIR}"
    download_pdfs "$TMP_JSON" "$DOWNLOAD_DIR"
fi

echo ""
echo "搜索完成！"
