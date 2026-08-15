# MoonLabelKit

MoonLabelKit 是一个用 MoonBit 编写的标注数据一致性检查与质量治理工具包，面向分类、序列标注和多标注者数据。它提供可复用 SDK、JSONL/CSV/TSV 解析器、统计指标、一致性系数、质量巡检和 Markdown/HTML 报告生成。

[![CI](https://github.com/Zy789kl/moonlabelkit/actions/workflows/ci.yml/badge.svg)](https://github.com/Zy789kl/moonlabelkit/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)

## 适用场景

- 在训练前发现重复样本、标签冲突、空文本、过短/过长文本和越界标签。
- 计算 Cohen's Kappa、Fleiss' Kappa、Krippendorff's Alpha、标签分布、熵、Gini 与序列片段密度。
- 把同一条样本的多个标注者记录安全合并，并输出可审阅的治理报告。
- 在 Native、Wasm 和 Wasm-GC 目标上运行，适合作为离线数据质量门禁或服务端 SDK。

## 项目规模与来源

仓库当前包含 21 个手写 `.mbt` 文件，约 1966 行 MoonBit 源码（含测试，不含 `_build` 生成物），并持续补充真实数据集、边界测试和基准样例。核心算法为原创 MoonBit 实现；仅使用 MoonBit 官方标准库 `moonbitlang/core/json` 与 `moonbitlang/core/math`。没有复制第三方实现或附带第三方数据集；示例数据为本项目编写的最小可公开样例。

## 安装

要求 MoonBit CLI 与编译器版本不低于 0.10.3。发布包名为 `Zy789kl/moonlabelkit`，仓库地址为 [GitHub](https://github.com/Zy789kl/moonlabelkit)，镜像仓库为 [GitLink](https://gitlink.org.cn/sgacc/moonlabelkit)。

```bash
moon update
moon install
moon check --deny-warn
moon test --target native --deny-warn
moon build --target wasm-gc
```

文件输入 CLI 使用 `moonbitlang/x` 的文件系统适配，项目已锁定兼容当前工具链的版本；执行 `moon update` 后如工具链升级，请重新运行完整 CI 检查。

## 快速运行

```bash
moon run cmd
```

命令会加载内置的多标注者情感分类示例，执行分布分析、一致性分析、重复检测、冲突检测和 Schema/长度巡检，并输出 Markdown 报告。也可以直接检查真实文件：

```bash
moon run cmd -- --input examples/sentiment_reviews.jsonl --format jsonl \
  --schema Positive,Negative,Neutral
moon run cmd -- --input examples/sentiment_reviews.csv --format csv \
  --schema Positive,Negative,Neutral
```

序列标注示例位于 `examples/ner_entities.jsonl`；分类示例位于 `examples/sentiment_reviews.jsonl` 和 `examples/sentiment_reviews.csv`。

## 包结构

| 包 | 作用 |
| --- | --- |
| `core` | Dataset、Sample、Annotation、LabelValue 与结构化错误 |
| `parser` | JSONL、CSV/TSV 严格解析与多标注记录合并 |
| `stats` | 标签分布、熵、Gini、不平衡和序列片段统计 |
| `agreement` | Cohen/Fleiss Kappa、Krippendorff Alpha 与两两矩阵 |
| `quality` | 重复、冲突、Schema、文本长度异常检测 |
| `report` / `cmd` | HTML/Markdown 报告和可运行入口 |

## 数据格式

分类 JSONL 每行至少包含 `id`、`text`、`label`、`annotator`；`split` 可选。序列标注每行包含 `id`、`text`、`spans`，其中 span 使用半开区间 `[start, end)`。CSV/TSV 解析器要求表头包含 `id,text,label,annotator`，缺列和非法记录会返回带行号的 `GovernanceError`。

## 测试与 CI

本地建议依次执行：

```bash
moon fmt
git diff --exit-code
moon info
moon check --deny-warn
moon test --target native --deny-warn
moon test --target all,native --deny-warn
moon test --target all,native --release --deny-warn
```

GitHub Actions 位于 `.github/workflows/ci.yml`，覆盖 Linux、macOS、Windows，并执行格式、信息、检查、全目标测试和 release 测试。若本机没有 Node.js，可先运行 `moon test --target native`；CI 会在完整环境执行 `all,native`。

## 开源合规

项目采用 [Apache License 2.0](LICENSE)。贡献者应在新增代码、生成代码、第三方代码、测试夹具或数据集时同步注明来源、许可证和再分发权利；不得提交密钥、个人敏感信息、商业数据或未获授权的样本。详细 API 与公式见 `docs/API.md` 和 `docs/THEORY.md`。

## 贡献与发布

请使用 Conventional Commits，确保提交包含真实功能、测试或文档改进。发布前应在干净工作树上完成 CI 命令并确认 `moon.mod` 的模块名、版本、许可证、README 和仓库链接一致。发布 Mooncakes 前使用：

```bash
moon publish --dry-run
moon publish
```

最终发布是否成功取决于本地 Mooncakes 登录状态、包名占用情况和服务端审核；这些状态不能仅由本地仓库推断。
