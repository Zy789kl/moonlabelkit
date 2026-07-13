# 🌌 MoonLabelKit: 标注数据一致性检查与质量治理引擎

[![MoonBit Version](https://img.shields.io/badge/MoonBit-v0.1.0-8A2BE2.svg)](https://www.moonbitlang.com/)
[![CI](https://github.com/Zy789kl/moonlabelkit/actions/workflows/test.yml/badge.svg)](https://github.com/Zy789kl/moonlabelkit/actions/workflows/test.yml)
[![Target](https://img.shields.io/badge/Target-Wasm--GC%20%7C%20Native-blue.svg)]()
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-13%20Passed-success.svg)]()

> **MoonLabelKit** 是一款基于 [MoonBit (月兔)](https://www.moonbitlang.com/) 语言开发的高性能、模块化 AI 与多模态数据标注一致性检查与质量治理引擎。专为解决高质量 AI 数据集准备中的**多标注者冲突、极度类别不平衡、标签规范越界及重复噪声样本**等数据工程核心痛点而设计。

---

## 📌 1. 选题背景与扩展性说明

在当前人工智能（尤其是现代大语言模型、分类系统与实体标注模型）的发展中，**“高质量的数据决定模型的上限”**已成为行业共识。然而，在实际的数据准备与众包标注场景中，常面临以下严重痛点：
1. **多标注者主观分歧大**：由于标注人员理解不同或任务标准模糊，同一样本常被不同标注人员赋予不同甚至完全矛盾的标签。传统简单比对难以给出清晰的统计显著性与整体一致性度量（如 Cohen's Kappa 与 Fleiss' Kappa）。
2. **长尾分布与类别严重失衡**：数据集中个别常用类别占据 90% 以上的数据量，稀缺类别极度缺乏，导致模型预测坍塌。
3. **数据格式与规范噪声多**：JSONL、CSV/TSV 数据在流转过程中常夹杂格式损坏、超出约定 Schema 定义的非法标签、超长/过短文本以及内容重复但标签冲突的“脏数据”。

### 为什么选择该领域作为 OSC 2026 参赛选题？
- **成熟交叉与高价值定位**：本选题处于**编译/系统语言与 AI 数据工程**的深度交叉领域，既发挥了 MoonBit 在结构化数据处理、内存安全与 Wasm-GC 高性能零拷贝上的核心优势，又具备极高的实用价值。
- **广阔的横向扩展性**：不仅支持经典的**多类别分类 (Classification)**，还天然原生支持**序列标注/实体识别 (Sequence Labeling / NER)** 以及**大模型问答/对齐评估 (Prompt-Response / LLM Alignment)**，未来可轻松扩展至图像/音频多模态元数据检查与自动化清洗流水线。
- **避免狭窄与同质化**：相比于简单的基础算法库封装或小型算子库，MoonLabelKit 是一个完整闭环的**工程级数据治理软件开发工具包 (SDK) 与命令行流水线 (CLI)**。

---

## 📦 2. 源码规模与来源说明 (Scale & Source Attribution)

### 2.1 原创声明与来源说明
> [!IMPORTANT]
> **本项目为完全原创的独立设计与开发项目**。整个架构、数据流定义、多标注者一致性统计算法（Cohen's Kappa / Fleiss' Kappa）、数据解析与质量巡检逻辑均针对 **OSC 2026 参赛标准**自底向上独立构建。未直接复制或搬运任何第三方开源项目的已有代码，所有核心算法均由纯 MoonBit 实现，依赖库仅限官方标准的 `@json` 和 `@math`。

### 2.2 源码规模统计 (Metrics)
全库纯 MoonBit 手写核心代码（不含自动生成的构建产物 `_build` 目录与第三方依赖包）共 **1,518 行**，拆分为 6 个高度内聚且零循环依赖的模块包：

| 包路径 (Package Path) | 核心职责 (Description) | 文件明细 | 纯代码行数 |
| :--- | :--- | :--- | :---: |
| `Zy789kl/moonlabelkit/core` | 领域数据模型定义与统一异常系统 `GovernanceError` | `types.mbt`, `error.mbt`, `core_test.mbt` | 271 |
| `Zy789kl/moonlabelkit/parser` | JSONL 与 CSV/TSV 结构化解析器及 Schema 校验 | `jsonl_parser.mbt`, `csv_parser.mbt`, `parser_test.mbt` | 306 |
| `Zy789kl/moonlabelkit/stats` | 标签频率分布、香农熵、基尼不平衡系数与序列密度统计 | `distribution.mbt`, `sequence_stats.mbt`, `stats_test.mbt` | 175 |
| `Zy789kl/moonlabelkit/agreement` | Cohen's Kappa（两两一致性）与 Fleiss' Kappa（多标注者一致性） | `cohen_kappa.mbt`, `fleiss_kappa.mbt`, `confusion_matrix.mbt`, `agreement_test.mbt` | 332 |
| `Zy789kl/moonlabelkit/quality` | 重复冲突巡检、样本内多标注分歧检测与 Schema 越界巡检 | `duplicate_detector.mbt`, `conflict_detector.mbt`, `outlier_detector.mbt`, `quality_test.mbt` | 223 |
| `Zy789kl/moonlabelkit/cmd` | 可执行主程序入口 `main` 与综合治理报告生成引擎 `report_generator` | `main.mbt`, `report_generator.mbt` | 211 |
| **合计 (Total)** | **全量代码、测试与工程逻辑** | **19 个 `.mbt` 源文件** | **1,518 行** |

---

## 🏗️ 3. 系统架构设计 (Architecture)

MoonLabelKit 遵循清晰的分层解耦设计，下层模块为上层提供纯粹无副作用的数据结构与计算接口，确保 Wasm 导出时具有极高的执行效率与低内存开销。

```
                   +--------------------------------------------+
                   |     CLI Entrypoint & Report Generator      |
                   |               (cmd/main.mbt)               |
                   +---------------------+----------------------+
                                         |
         +-------------------------------+-------------------------------+
         |                               |                               |
         v                               v                               v
+-----------------+             +-----------------+             +-----------------+
|  stats Package  |             |agreement Package|             | quality Package |
| (Entropy/Gini)  |             | (Cohen/Fleiss)  |             | (Conflicts/Dups)|
+--------+--------+             +--------+--------+             +--------+--------+
         |                               |                               |
         +-------------------------------+-------------------------------+
                                         |
                                         v
                         +-------------------------------+
                         |        parser Package         |
                         |   (JSONL/CSV Strict Parser)   |
                         +---------------+---------------+
                                         |
                                         v
                         +-------------------------------+
                         |         core Package          |
                         | (Dataset/Sample/Annotation API|
                         +-------------------------------+
```

---

## 💡 4. 核心功能与特性 (Core Features)

1. **统一的高扩展数据模型 (`core`)**：
   - 兼容 `Single`（单类别）、`Multi`（多类别）、`Spans`（序列标注/实体切分区间）及 `Scores`（浮点权重分布）。
   - 采用 MoonBit 原生 `suberror` 构建结构化异常处理体系 `GovernanceError`，提供精确到解析行号与 Schema 越界的强类型错误反馈。
2. **鲁棒的结构化数据引擎 (`parser`)**：
   - 高性能单行扫描 JSONL 解析与 CSV/TSV 表格字段分拆，自动捕获转义字符与字段缺失异常。
   - 支持多标注人员以相同 Sample ID 独立提交数据，解析引擎自动合并 (`add_sample_or_merge`) 为统一的多标注数据样本。
3. **深度的统计学与信息熵诊断 (`stats`)**：
   - 精密计算**香农信息熵 (Shannon Entropy)** 与**基尼不平衡系数 (Gini Imbalance)**，针对最大与最小类别比超标的情况提供自动化治理警告。
   - 针对序列标注任务深入统计实体密度与 Span 平均字符分布。
4. **权威的标注一致性量化评估 (`agreement`)**：
   - 实现 **Cohen's Kappa ($\kappa$)**，支持任意两位标注者之间的两两混淆矩阵与统计学评级（如 `Almost Perfect`, `Moderate Agreement` 等）。
   - 实现 **Fleiss' Kappa ($\bar{\kappa}$)**，直接针对 $N \ge 2$ 的任意规模多标注团队进行总体协同度计算。
5. **立体的质量缺陷自动化巡检 (`quality`)**：
   - **重复样本检测**：精确匹配或归一化匹配完全相同的文本，并指出其中是否夹杂**标签冲突**。
   - **样本内分歧识别**：自动甄别多位标注者对同一文本给出的分歧标签并划分严重程度（如 `High (Severe Divergence)` 或 `Moderate (Binary Disagreement)`）。
   - **规范越界与长度异常**：扫描文本过短（如残留单个无意义字符）以及超出 Schema 预设范围的污染标签。

---

## 🚀 5. 快速上手与使用指南 (Quickstart Guide)

### 5.1 环境要求
请确保已安装 [MoonBit 官方工具链 (MoonBit Toolchain)](https://www.moonbitlang.com/download/) (v0.1.x 或更高版本)。

### 5.2 代码构建与类型检查
在仓库根目录下执行：
```bash
# 1. 语法与类型全面安全检查
moon check

# 2. 编译构建到 Wasm-GC 目标
moon build --target wasm-gc
```

### 5.3 运行全量单元测试
本项目配置了 **13 个综合测试用例**，严格覆盖边界条件、完全不一致测试及多标注合并场景：
```bash
moon test
```
**输出示例**：
```text
Total tests: 13, passed: 13, failed: 0.
```

### 5.4 一键执行数据治理与生成检查报告
直接运行主模块入口，即可自动加载模拟多标注电商/手机评测数据集并打印标准的 Markdown 综合治理报告：
```bash
moon run cmd
```

**命令行自动生成报告效果预览**：
```markdown
==========================================================
 🌌 MoonLabelKit v0.1.0 - Annotation Data Governance Engine 
==========================================================

# 📊 MoonLabelKit 数据治理与标注一致性综合检查报告

## 1. 数据集基本信息 (Dataset Overview)
- **数据集名称**: `Mobile_Phone_Reviews_MultiAnn_v1`
- **任务类型**: `文本分类 / 标签分类 (Classification)`
- **样本总数**: `6`
- **预设类别 Schema**: `["Positive", "Negative", "Neutral"]`
- **参与标注者列表**: `["Alice", "Bob", "Charlie"]`

## 2. 标签分布与信息熵分析 (Label Distribution & Entropy)
- **总标注条目 (Total Annotations)**: `7`
- **香农信息熵 (Shannon Entropy)**: `1.8423709931771088` bit
- **基尼不平衡系数 (Gini Imbalance)**: `0.6938775510204082`
- **最大/最小类别比 (Max/Min Ratio)**: `3`

| 类别标签 (Category) | 出现次数 (Count) | 占比 (Proportion) |
| :--- | :--- | :--- |
| `Positive` | 3 | 42.857142857142854% |
| `Neutral` | 2 | 28.57142857142857% |
| `Negative` | 1 | 14.285714285714285% |
| `SuperGood` | 1 | 14.285714285714285% |

## 3. 多标注者一致性检查 (Inter-Annotator Agreement)
### Fleiss' Kappa (多标注者整体一致性)
- **多标注覆盖样本数**: `2`
- **观察一致率 (Observed Agreement)**: `0.6666666666666666`
- **随机期望一致率 (Expected Agreement)**: `0.3600000000000001`
- **Fleiss' Kappa (kappa)**: **`0.4791666666666665`** (`Moderate Agreement`)

### 两两标注者一致性矩阵 (Pairwise Cohen's Kappa)
| 标注者 A | 标注者 B | 共同样本数 | Cohen's Kappa (kappa) | 一致性评级 |
| :--- | :--- | :--- | :--- | :--- |
| `Alice` | `Bob` | 2 | **1** | `Almost Perfect / Excellent Agreement` |
| `Alice` | `Charlie` | 1 | **0** | `Slight Agreement` |
| `Bob` | `Charlie` | 1 | **0** | `Slight Agreement` |

## 4. 质量巡检与异常检测 (Quality & Outlier Inspection)
### 4.1 重复样本检测 (Duplicate Samples)
- ⚠️ **检测到 `1` 组重复文本样本**:
  - 归一化文本: `"OK phone for the price, decent screen."` | 关联ID: `["rev_003", "rev_006_dup"]` | 状态: ⚠️ **存在标签冲突** (`["Neutral", "Positive"]`)

### 4.2 样本内标注分歧与歧义项 (Ambiguous Samples)
- ⚠️ **发现 `1` 个存在多标注严重分歧的样本**:
  - ID: `rev_001` | 严重度: `Moderate (Binary Disagreement)` | 文本概览: `"This phone camera is absolutely stunning and super fast!"` | 各方标注: `{Alice: ["Positive"], Bob: ["Positive"], Charlie: ["Neutral"]}`

### 4.3 Schema 规范性与长度异常 (Schema & Length Outliers)
- ❌ **检测到 `2` 项规范异常**:
  - 样本ID: `rev_004` | 异常类型: `TextTooShort` | 详细描述: Sample text length (1) is below minimum required threshold (2)
  - 样本ID: `rev_005` | 异常类型: `OutOfSchemaLabel` | 详细描述: Found labels not defined in official dataset schema
```

---

## 📜 6. 许可证与仓库规范 (License & Conventions)

本项目基于 [Apache License 2.0](LICENSE) 协议授权开源。
仓库默认远程分支为 `main`，提交历史遵循 **Conventional Commits** 标准规范：
- `feat(core)`: 领域模型与异常结构定义
- `feat(parser)`: JSONL / CSV 高并发解析流
- `feat(stats)`: 香农熵与基尼系数分布统计
- `feat(agreement)`: Cohen's Kappa / Fleiss' Kappa 一致性矩阵
- `feat(quality)`: 重复样本、歧义项与异常标签巡检
- `feat(cmd)`: 综合质量治理报告输出与 CLI 引擎

### 5.5 仓库自检与 CI
仓库已补齐 GitHub Actions 持续集成，工作流位于 [`.github/workflows/test.yml`](.github/workflows/test.yml)。

本地和 CI 统一执行以下检查：
- `moon check --deny-warn`
- `moon info --target all`
- `moon fmt` 后检查 `git diff --exit-code`
- `moon test --target all,native`
- `moon test --target all,native --release`

当前流程对齐 MoonBit 0.10.3 工具链，方便在最新稳定版环境下稳定复现。

---
*Created for MoonBit OSC 2026 Open Source Competition.*
