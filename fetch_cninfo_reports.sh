#!/bin/bash

# 从巨潮资讯网获取A股上市公司年报/半年度报告
# Usage: ./fetch_cninfo_reports.sh <公司名称或代码> [开始日期] [结束日期]

set -euo pipefail

COMPANY_KEY="${1:-}"
START_DATE_INPUT="${2:-}"
END_DATE_INPUT="${3:-}"
JSON_ONLY="${CNINFO_JSON_ONLY:-0}"

if [ -z "$COMPANY_KEY" ]; then
    if [ "$JSON_ONLY" != "1" ]; then
        echo "错误: 请提供公司名称或股票代码"
        echo "用法: $0 <公司名称或代码> [开始日期] [结束日期]"
        echo "示例: $0 平安银行 2024-01-01 2024-12-31"
    fi
    exit 1
fi

normalize_date() {
    local input="$1"
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
    return 1
}

CURRENT_YEAR="$(date +%Y)"
DEFAULT_START="${CURRENT_YEAR}-01-01"
DEFAULT_END="$(date +%F)"

START_DATE="$(normalize_date "${START_DATE_INPUT:-$DEFAULT_START}")" || {
    echo "错误: 开始日期格式不正确（支持 YYYY-MM-DD 或 DD/MM/YYYY）"
    exit 1
}
END_DATE="$(normalize_date "${END_DATE_INPUT:-$DEFAULT_END}")" || {
    echo "错误: 结束日期格式不正确（支持 YYYY-MM-DD 或 DD/MM/YYYY）"
    exit 1
}

API_URL="${API_URL:-https://www.cninfo.com.cn/new/hisAnnouncement/query}"
BASE_URL="${BASE_URL:-https://static.cninfo.com.cn/}"
PAGE_SIZE="${PAGE_SIZE:-30}"
MAX_PAGES="${MAX_PAGES:-5}"
PLATE="${PLATE:-sz;sh}"
CATEGORY="${CATEGORY:-category_ndbg_szsh;category_bndbg_szsh;}"
CNINFO_BROWSER_FLAGS="${CNINFO_BROWSER_FLAGS:---headed}"

if [ "$JSON_ONLY" != "1" ]; then
    echo "正在搜索 ${COMPANY_KEY} 的A股财报..."
    echo "日期范围: ${START_DATE} ~ ${END_DATE}"
    echo ""
fi

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys
print(json.dumps(sys.argv[1]))
PY
}

TMP_JS="$(mktemp /tmp/cninfo_eval.XXXXXX.js)"
trap 'rm -f "$TMP_JS"' EXIT

python3 - "$COMPANY_KEY" "$START_DATE" "$END_DATE" "$PAGE_SIZE" "$MAX_PAGES" "$PLATE" "$CATEGORY" "$API_URL" "$BASE_URL" > "$TMP_JS" <<'PY'
import json
import sys

company_key, start_date, end_date, page_size, max_pages, plate, category, api_url, base_url = sys.argv[1:]

def js(value):
    return json.dumps(value)

print(f"const companyKey = {js(company_key)};")
print(f"const startDate = {js(start_date)};")
print(f"const endDate = {js(end_date)};")
print(f"const pageSize = Number({js(page_size)});")
print(f"const maxPages = Math.max(1, Number({js(max_pages)}));")
print(f"const plate = {js(plate)};")
print(f"const category = {js(category)};")
print(f"const apiUrl = {js(api_url)};")
print(f"const baseUrl = {js(base_url)};")

print("""
function postPage(pageNum) {
  const payload = {
    pageNum: String(pageNum),
    pageSize: String(pageSize),
    column: "szse",
    tabName: "fulltext",
    plate: plate,
    stock: "",
    searchkey: companyKey,
    secid: "",
    category: category,
    trade: "",
    seDate: `${startDate}~${endDate}`,
    sortName: "",
    sortType: "",
    isHLtitle: "true",
  };

  const xhr = new XMLHttpRequest();
  xhr.open("POST", apiUrl, false);
  xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
  xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
  xhr.send(new URLSearchParams(payload).toString());

  if (xhr.status < 200 || xhr.status >= 300) {
    throw new Error(`请求失败 HTTP ${xhr.status}`);
  }
  return JSON.parse(xhr.responseText);
}

let first;
try {
  first = postPage(1);
} catch (err) {
  throw new Error(`请求失败: ${err.message}`);
}

let announcements = Array.isArray(first.announcements) ? first.announcements.slice() : [];
const totalRecords = Number(first.totalRecordNum || announcements.length);
const totalPages = Math.max(1, Math.ceil(totalRecords / pageSize));
const pagesToFetch = Math.min(totalPages, maxPages);

for (let page = 2; page <= pagesToFetch; page += 1) {
  try {
    const data = postPage(page);
    if (Array.isArray(data.announcements)) {
      announcements = announcements.concat(data.announcements);
    }
  } catch (err) {
    break;
  }
}

const seen = new Set();
const results = [];
for (const ann of announcements) {
  const title = String(ann.announcementTitle || "").replace(/<[^>]*>/g, "").trim();
  if (title.includes("摘要") || title.includes("摘 要")) {
    continue;
  }
  const adjunctUrl = String(ann.adjunctUrl || "").trim();
  if (!adjunctUrl || !adjunctUrl.toLowerCase().includes(".pdf")) {
    continue;
  }
  const fullUrl = `${baseUrl.replace(/\\/+$/, "")}/${adjunctUrl.replace(/^\\/+/, "")}`;
  if (seen.has(fullUrl)) {
    continue;
  }
  seen.add(fullUrl);
  const item = { name: title, url: fullUrl };
  const ts = Number(ann.announcementTime || 0);
  if (ts > 0) {
    item.date = new Date(ts).toISOString().slice(0, 10);
  }
  results.push(item);
}

results;
""")
PY

agent-browser $CNINFO_BROWSER_FLAGS open http://www.cninfo.com.cn/ >/dev/null
agent-browser $CNINFO_BROWSER_FLAGS wait --load networkidle >/dev/null
agent-browser $CNINFO_BROWSER_FLAGS eval --stdin < "$TMP_JS" | python3 -m json.tool

if [ "$JSON_ONLY" != "1" ]; then
    echo ""
    echo "搜索完成！"
fi
