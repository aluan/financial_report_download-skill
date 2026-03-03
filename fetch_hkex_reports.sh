#!/bin/bash

# 从披露易平台获取香港上市公司财报
# Usage: ./fetch_hkex_reports.sh <公司名称> [开始日期]

set -e


COMPANY_NAME_TRADITIONAL="${1:-}"
START_DATE="${2:-01/01/2024}"

if [ -z "$COMPANY_NAME_TRADITIONAL" ]; then
    echo "错误: 请提供公司名称"
    echo "用法: $0 <公司名称> [开始日期]"
    echo "示例: $0 海底捞 01/01/2025"
    exit 1
fi

# 将简体公司名称转换为繁体

echo "正在搜索 ${COMPANY_NAME_TRADITIONAL} 的财报..."
echo "开始日期: ${START_DATE}"
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

# 7. 选择开始日期
echo "步骤 7/9: 选择开始日期..."
agent-browser --headed snapshot -i > /tmp/hkex_snapshot.txt

# 点击开始日期输入框打开日期选择器
START_DATE_REF=$(grep "開始日期" /tmp/hkex_snapshot.txt | grep "textbox" | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
agent-browser --headed click "$START_DATE_REF"
agent-browser --headed wait 1000

# 从START_DATE提取年月日 (格式: DD/MM/YYYY)
DAY=$(echo "$START_DATE" | cut -d'/' -f1)
MONTH=$(echo "$START_DATE" | cut -d'/' -f2)
YEAR=$(echo "$START_DATE" | cut -d'/' -f3)

# 获取日期选择器快照
agent-browser --headed snapshot -i > /tmp/hkex_date_picker.txt

# 点击年份按钮
YEAR_BUTTON_REF=$(grep "button \"$YEAR\"" /tmp/hkex_date_picker.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
if [ -n "$YEAR_BUTTON_REF" ]; then
  agent-browser --headed click "$YEAR_BUTTON_REF"
  agent-browser --headed wait 500
fi

# 点击月份按钮
agent-browser --headed snapshot -i > /tmp/hkex_date_picker.txt
MONTH_BUTTON_REF=$(grep "button \"$MONTH\"" /tmp/hkex_date_picker.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
if [ -n "$MONTH_BUTTON_REF" ]; then
  agent-browser --headed click "$MONTH_BUTTON_REF"
  agent-browser --headed wait 500
fi

# 点击日期按钮
agent-browser --headed snapshot -i > /tmp/hkex_date_picker.txt
DAY_BUTTON_REF=$(grep "button \"$DAY\"" /tmp/hkex_date_picker.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
if [ -n "$DAY_BUTTON_REF" ]; then
  agent-browser --headed click "$DAY_BUTTON_REF"
  agent-browser --headed wait 500
fi

# 点击页面空白处关闭日期选择器
agent-browser --headed eval 'document.body.click()'
agent-browser --headed wait 500

# 8. 点击搜索按钮
echo "步骤 8/9: 点击搜索按钮..."
SEARCH_REF=$(grep "link \"搜尋\"" /tmp/hkex_snapshot.txt | head -1 | sed -n 's/.*\[ref=\(e[0-9]*\)\].*/\1/p')
agent-browser --headed click "$SEARCH_REF"
agent-browser --headed wait --load networkidle
agent-browser --headed wait 2000

# 9. 提取年报和中期报告链接
echo ""
echo "步骤 9/9: 正在提取财报链接..."
agent-browser --headed eval --stdin <<'EVALEOF' | python3 -m json.tool
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

echo ""
echo "搜索完成！"
