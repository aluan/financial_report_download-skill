# 披露易财报查询 Skill

从香港交易所披露易平台与巨潮资讯网查询上市公司的年报和中期报告。

**重要提示**：当用户输入简体中文公司名称时，AI会自动将其转换为繁体中文后再调用脚本进行查询。

## 功能

- 自动搜索指定公司的财务报告
- 支持设置搜索起始日期
- 提取年报和中期报告的PDF下载链接
- 可视化浏览器模式，方便调试
- **自动简繁转换**：港股流程的简繁转换由上层调用方（skill/模型）处理，脚本直接使用传入名称
- **A股支持**：通过巨潮资讯网获取A股年报/半年度报告
- **本地下载**：可选将PDF直接下载到本地目录

## 使用方法

```bash
# 港股
/fetch-hkex-reports 海底捞
/fetch-hkex-reports 保利物业 01/01/2024
```

```bash
# 自动判断市场（推荐）
scripts/fetch_reports.sh 海底捞
scripts/fetch_reports.sh 平安银行 2024-01-01 2024-12-31
scripts/fetch_reports.sh 平安银行 2024-01-01 2024-12-31 --download
scripts/fetch_reports.sh 港股:海底捞 01/01/2025 31/12/2025 --download-dir ./pdfs
```

```bash
# A股（直接脚本）
scripts/fetch_cninfo_reports.sh 平安银行 2024-01-01 2024-12-31
scripts/fetch_cninfo_reports.sh 平安银行 2024-01-01 2024-12-31 --download
```

**注意**：可以直接输入简体中文公司名称（如"海底捞"），脚本会自动转换为繁体中文（"海底撈"）进行查询。

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

## 输出

返回JSON格式的财报链接列表，包含：
- `name`: 报告名称（如"2024年年報"）
- `url`: PDF文件下载链接

如启用 `--download`，会将PDF保存到本地目录（默认 `./downloads`），并匹配查询的时间范围（港股按披露易链接日期过滤）。

## 示例

查询中海物业2025年以来的财报：

```bash
/fetch-hkex-reports 中海物业 01/01/2025
```

输出：
```json
[
  {
    "name": "2025年中期報告",
    "url": "https://www1.hkexnews.hk/listedco/listconews/sehk/2025/0915/2025091500166_c.pdf"
  },
  {
    "name": "2024年年報",
    "url": "https://www1.hkexnews.hk/listedco/listconews/sehk/2025/0429/2025042900354_c.pdf"
  }
]
```

## 注意事项

- 需要安装 agent-browser 工具（港股与A股脚本均需）
- 使用可视化模式（--headed）方便查看执行过程
- 港股公司名称支持简体或繁体中文，简体会在上层调用方转换为繁体后再传入脚本
- 日期格式必须为 DD/MM/YYYY（日/月/年）
- 自动判断市场以股票代码为准（如 `600000`、`SH600000`、`SZ000001`），公司名称默认按港股处理
- 如需强制A股或港股，可用前缀 `A:`、`A股:` 或 `HK:`、`港股:`
- 常见公司名称转换示例：
  - 海底捞 → 海底撈
  - 物业 → 物業
  - 服务 → 服務
  - 传媒 → 傳媒
  - 集团 → 集團
