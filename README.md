# 披露易财报查询 Skill

从香港交易所披露易平台自动查询上市公司的年报和中期报告。

## 功能特性

- 🔍 自动搜索指定公司的财务报告
- 📅 支持设置搜索起始日期
- 📄 提取年报和中期报告的PDF下载链接
- 🌐 可视化浏览器模式，方便调试
- 🔄 **自动简繁转换**：支持输入简体中文公司名称，会自动转换为繁体中文进行查询

## 安装

### 前置要求

- [agent-browser](https://github.com/anthropics/agent-browser) - 浏览器自动化工具
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
chmod +x fetch_hkex_reports.sh
```

3. （可选）作为Claude Code skill安装：
```bash
# 复制到Claude skills目录
cp -r . ~/.claude/skills/fetch-hkex-reports/
```

## 使用方法

### 直接使用脚本

```bash
# 基本用法（支持简体中文）
./fetch_hkex_reports.sh 海底捞

# 指定起始日期
./fetch_hkex_reports.sh 保利物业 01/01/2024

# 查询最近一年的报告
./fetch_hkex_reports.sh 碧桂园服务 01/01/2025
```

### 作为Claude Code Skill使用

安装后，在Claude Code中使用：

```bash
/fetch-hkex-reports 海底捞
/fetch-hkex-reports 保利物业 01/01/2024
```

## 参数说明

- `公司名称` (必需): 要查询的香港上市公司名称（支持简体或繁体中文）
- `开始日期` (可选): 搜索起始日期，格式为 DD/MM/YYYY，默认为 01/01/2024

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

## 工作原理

脚本通过以下步骤自动化查询流程：

1. 打开披露易中文网站
2. 输入公司名称（自动转换简体为繁体）
3. 选择标题类别
4. 选择"財務報表/環境、社會及管治資料"
5. 通过日期选择器设置开始日期
6. 执行搜索
7. 提取年报和中期报告的PDF链接

## 注意事项

- 公司名称支持简体或繁体中文，会自动转换为繁体进行查询
- 日期格式必须为 DD/MM/YYYY（日/月/年）
- 使用可视化模式（--headed）方便查看执行过程
- 常见公司名称转换示例：
  - 海底捞 → 海底撈
  - 物业 → 物業
  - 服务 → 服務
  - 传媒 → 傳媒
  - 集团 → 集團

## 示例

查询海底捞2025年以来的财报：

```bash
./fetch_hkex_reports.sh "海底捞" "01/01/2025"
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
