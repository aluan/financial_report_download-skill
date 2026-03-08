# A股、港股财报下载 Skill

从香港交易所披露易平台与巨潮资讯网自动查询上市公司的年报和中期报告并下载。

## 功能特性

- 🔍 自动搜索指定公司的财务报告
- 📅 支持设置搜索起始日期
- 📄 提取年报和中期报告的PDF下载链接
- 🌐 可视化浏览器模式，方便调试
- 🔄 **自动简繁转换**：港股流程的简繁转换由上层调用方（skill/模型）处理，脚本直接使用传入名称
- 🇨🇳 **A股支持**：通过巨潮资讯网获取A股年报/半年度报告
- ⬇️ **本地下载**：可选将PDF直接下载到本地目录

## 安装

### 前置要求

- [agent-browser](https://github.com/anthropics/agent-browser) - 浏览器自动化工具（港股与A股脚本均需）
- Python 3.x（用于JSON格式化）
- Bash shell

### 安装步骤

1. 克隆本仓库：
```bash
git clone https://github.com/luanqq/fetch-hkex-reports-skill.git
cd fetch-hkex-reports-skill
```

2. 赋予脚本执行权限：
```bash
chmod +x scripts/fetch_hkex_reports.sh
chmod +x scripts/fetch_cninfo_reports.sh
chmod +x scripts/fetch_reports.sh
```

3. （可选）作为Claude Code skill安装：
```bash
# 复制到Claude skills目录
cp -r . ~/.claude/skills/fetch-hkex-reports/
```

## 使用方法

### 直接使用脚本

```bash
# 自动判断市场（推荐）
scripts/fetch_reports.sh 海底捞
scripts/fetch_reports.sh 平安银行 2024-01-01 2024-12-31
scripts/fetch_reports.sh 平安银行 2024-01-01 2024-12-31 --download
scripts/fetch_reports.sh 港股:海底捞 01/01/2025 31/12/2025 --download-dir ./pdfs

# 强制A股或港股（可选）
scripts/fetch_reports.sh A:平安银行 2024-01-01 2024-12-31
scripts/fetch_reports.sh 港股:海底捞 01/01/2024

# 仅港股
scripts/fetch_hkex_reports.sh 海底捞

# 仅A股
scripts/fetch_cninfo_reports.sh 平安银行 2024-01-01 2024-12-31
scripts/fetch_cninfo_reports.sh 平安银行 2024-01-01 2024-12-31 --download
```

### 作为Claude Code Skill使用

安装后，在Claude Code中使用：

```bash
/fetch-hkex-reports 海底捞
/fetch-hkex-reports 保利物业 01/01/2024
```

## 参数说明

- `公司名称` (必需): 要查询的公司名称或股票代码
- `开始日期` (可选): 
  - 港股脚本格式为 DD/MM/YYYY 或 YYYY-MM-DD，默认为 01/01/2024
  - A股脚本格式为 YYYY-MM-DD 或 DD/MM/YYYY，默认为当年 01-01
- `结束日期` (可选):
  - 港股脚本格式为 DD/MM/YYYY 或 YYYY-MM-DD（用于下载过滤及尽量设置结束日期）
  - A股脚本格式为 YYYY-MM-DD 或 DD/MM/YYYY，默认为今天
- `--download` (可选): 下载搜索到的PDF到本地目录
- `--download-dir` (可选): 指定下载目录，默认 `./downloads`

## 输出格式

返回JSON格式的财报链接列表：

```json
[
  {
    "name": "2025年中期報告",
    "url": "https://www1.hkexnews.hk/listedco/listconews/sehk/2025/0922/2025092200399_c.pdf"
  },
  {
    "name": "2024年中期報告",
    "url": "https://www1.hkexnews.hk/listedco/listconews/sehk/2024/0923/2024092300569_c.pdf"
  }
]
```

如启用 `--download`，会将PDF保存到本地目录（默认 `./downloads`），并匹配查询的时间范围（港股按披露易链接日期过滤）。

## 工作原理

脚本通过以下步骤自动化查询流程：

港股（披露易）：
1. 打开披露易中文网站
2. 输入公司名称（自动转换简体为繁体）
3. 选择标题类别
4. 选择"財務報表/環境、社會及管治資料"
5. 通过日期选择器设置开始日期
6. 执行搜索
7. 提取年报和中期报告的PDF链接

A股（巨潮资讯网）：
1. 提交公告查询请求
2. 过滤年报/半年度报告PDF
3. 生成完整PDF下载链接

## 注意事项

- 港股公司名称支持简体或繁体中文，简体会在上层调用方转换为繁体后再传入脚本
- 日期格式必须为 DD/MM/YYYY（日/月/年）
- 使用可视化模式（--headed）方便查看执行过程
- 自动判断市场以股票代码为准（如 `600000`、`SH600000`、`SZ000001`），公司名称默认按港股处理
- 如需强制A股或港股，可用前缀 `A:`、`A股:` 或 `HK:`、`港股:`
- 常见公司名称转换示例：
  - 海底捞 → 海底撈
  - 物业 → 物業
  - 服务 → 服務
  - 传媒 → 傳媒
  - 集团 → 集團

## 示例

查询海底捞2025年以来的财报：

```bash
scripts/fetch_hkex_reports.sh "海底捞" "01/01/2025"
```

输出：
```json
[
  {
    "name": "2025年中期報告",
    "url": "https://www1.hkexnews.hk/listedco/listconews/sehk/2025/0922/2025092200399_c.pdf"
  },
  {
    "name": "2024年中期報告",
    "url": "https://www1.hkexnews.hk/listedco/listconews/sehk/2024/0923/2024092300569_c.pdf"
  }
]
```

查询A股平安银行2024年度财报：

```bash
scripts/fetch_cninfo_reports.sh "平安银行" "2024-01-01" "2024-12-31"
```

## 故障排除

如果脚本执行失败：

1. 检查 agent-browser 是否正确安装
2. 确认公司名称拼写正确
3. 查看 /tmp/hkex_snapshot.txt 文件了解页面状态
4. 使用 --headed 模式观察浏览器操作过程

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License

## 作者

luanqq

## 相关链接

- [香港交易所披露易平台](https://www.hkexnews.hk/)
- [agent-browser](https://github.com/anthropics/agent-browser)
- [Claude Code](https://www.anthropic.com/)
