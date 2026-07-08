///|
/// 辅助将字符串数组输出为可读文本列表
fn format_string_array(arr : Array[String]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("[")
  let mut first = true
  for item in arr {
    if !first {
      buf.write_string(", ")
    }
    first = false
    buf.write_string("\"\{item}\"")
  }
  buf.write_string("]")
  buf.to_string()
}

///|
/// 辅助将 Map 格式的多方标注输出为更清晰的字符串，避免调试宏警告
fn format_annotator_labels(map : Map[String, Array[String]]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{")
  let mut first = true
  for k, v in map {
    if !first {
      buf.write_string(", ")
    }
    first = false
    buf.write_string(k)
    buf.write_string(": [")
    let mut f_arr = true
    for item in v {
      if !f_arr {
        buf.write_string(", ")
      }
      f_arr = false
      buf.write_string("\"\{item}\"")
    }
    buf.write_string("]")
  }
  buf.write_string("}")
  buf.to_string()
}

///|
/// 生成完整的数据质量与标注一致性检查评估报告 (Markdown 格式文本)
pub fn generate_governance_report(dataset : @core.Dataset) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# 📊 MoonLabelKit 数据治理与标注一致性综合检查报告\n\n")
  buf.write_string("## 1. 数据集基本信息 (Dataset Overview)\n")
  buf.write_string("- **数据集名称**: `\{dataset.name}`\n")
  let task_str = match dataset.task_type {
    Classification => "文本分类 / 标签分类 (Classification)"
    SequenceLabeling => "序列标注 / 实体识别 (Sequence Labeling)"
    Tabular => "表格结构化数据 (Tabular)"
    PromptResponse => "大模型问答对/评估 (Prompt-Response / LLM Evaluation)"
  }
  buf.write_string("- **任务类型**: `\{task_str}`\n")
  buf.write_string("- **样本总数**: `\{dataset.samples.length()}`\n")
  let schema_str = format_string_array(dataset.schema_labels)
  buf.write_string("- **预设类别 Schema**: `\{schema_str}`\n")
  let ann_str = format_string_array(dataset.get_all_annotators())
  buf.write_string("- **参与标注者列表**: `\{ann_str}`\n\n")

  // 分布与熵统计
  buf.write_string("## 2. 标签分布与信息熵分析 (Label Distribution & Entropy)\n")
  let dist = @stats.compute_label_distribution(dataset)
  buf.write_string("- **总标注条目 (Total Annotations)**: `\{dist.total_annotations}`\n")
  buf.write_string("- **香农信息熵 (Shannon Entropy)**: `\{dist.shannon_entropy}` bit\n")
  buf.write_string("- **基尼不平衡系数 (Gini Imbalance)**: `\{dist.gini_imbalance}`\n")
  buf.write_string("- **最大/最小类别比 (Max/Min Ratio)**: `\{dist.max_min_ratio}`\n")
  if @stats.is_severely_imbalanced(dist, threshold=5.0) {
    buf.write_string("  > ⚠️ **警告**: 数据集类别分布存在显著不平衡！建议对极度稀缺类别实施数据增强或重采样治理。\n")
  }
  buf.write_string("\n| 类别标签 (Category) | 出现次数 (Count) | 占比 (Proportion) |\n")
  buf.write_string("| :--- | :--- | :--- |\n")
  for k, v in dist.frequency {
    let p = match dist.proportions.get(k) {
      Some(val) => val
      None => 0.0
    }
    buf.write_string("| `\{k}` | \{v} | \{p * 100.0}% |\n")
  }
  buf.write_string("\n")

  // 序列标注特有指标
  match dataset.task_type {
    SequenceLabeling => {
      buf.write_string("## 2.1 序列片段特征统计 (Sequence Span Density)\n")
      let seq_stats = @stats.compute_sequence_stats(dataset)
      buf.write_string("- **实体片段总数**: `\{seq_stats.total_spans}`\n")
      buf.write_string("- **平均每样本实体数**: `\{seq_stats.spans_per_sample_avg}`\n")
      buf.write_string("- **平均片段字符长度**: `\{seq_stats.avg_span_length}`\n")
      buf.write_string("- **最长片段字符数**: `\{seq_stats.max_span_length}`\n\n")
    }
    _ => ()
  }

  // 标注者一致性分析
  buf.write_string("## 3. 多标注者一致性检查 (Inter-Annotator Agreement)\n")
  let fleiss = try {
    @agreement.compute_fleiss_kappa(dataset)
  } catch {
    _ => {
      sample_count: 0,
      avg_annotators_per_sample: 0.0,
      observed_agreement: 0.0,
      expected_agreement: 0.0,
      kappa_score: 0.0,
      interpretation: "N/A",
    }
  }
  if fleiss.sample_count > 0 {
    buf.write_string("### Fleiss' Kappa (多标注者整体一致性)\n")
    buf.write_string("- **多标注覆盖样本数**: `\{fleiss.sample_count}`\n")
    buf.write_string("- **观察一致率 (Observed Agreement)**: `\{fleiss.observed_agreement}`\n")
    buf.write_string("- **随机期望一致率 (Expected Agreement)**: `\{fleiss.expected_agreement}`\n")
    buf.write_string("- **Fleiss' Kappa (kappa)**: **`\{fleiss.kappa_score}`** (`\{fleiss.interpretation}`)\n\n")
  }

  let matrix = @agreement.compute_pairwise_agreement_matrix(dataset)
  if matrix.length() > 0 {
    buf.write_string("### 两两标注者一致性矩阵 (Pairwise Cohen's Kappa)\n")
    buf.write_string("| 标注者 A | 标注者 B | 共同样本数 | Cohen's Kappa (kappa) | 一致性评级 |\n")
    buf.write_string("| :--- | :--- | :--- | :--- | :--- |\n")
    for item in matrix {
      buf.write_string("| `\{item.annotator_a}` | `\{item.annotator_b}` | \{item.common_samples} | **\{item.kappa}** | `\{item.interpretation}` |\n")
    }
    buf.write_string("\n")
  }

  // 数据质量冲突与异常巡检
  buf.write_string("## 4. 质量巡检与异常检测 (Quality & Outlier Inspection)\n")
  let dups = @quality.detect_duplicate_samples(dataset)
  buf.write_string("### 4.1 重复样本检测 (Duplicate Samples)\n")
  if dups.length() == 0 {
    buf.write_string("- ✅ 未检测到文本完全相同或归一化一致的重复样本。\n\n")
  } else {
    buf.write_string("- ⚠️ **检测到 `\{dups.length()}` 组重复文本样本**:\n")
    for d in dups {
      let conflict_str = if d.has_conflicting_labels { "⚠️ **存在标签冲突**" } else { "✅ 标签一致" }
      let u_lbl_str = format_string_array(d.unique_labels)
      let ids_str = format_string_array(d.sample_ids)
      buf.write_string("  - 归一化文本: `\"\{d.normalized_text}\"` | 关联ID: `\{ids_str}` | 状态: \{conflict_str} (`\{u_lbl_str}`)\n")
    }
    buf.write_string("\n")
  }

  let conflicts = @quality.detect_label_conflicts(dataset)
  buf.write_string("### 4.2 样本内标注分歧与歧义项 (Ambiguous Samples)\n")
  if conflicts.length() == 0 {
    buf.write_string("- ✅ 所有的多标注样本均未发现标注者分歧。\n\n")
  } else {
    buf.write_string("- ⚠️ **发现 `\{conflicts.length()}` 个存在多标注严重分歧的样本**:\n")
    for c in conflicts {
      let lbl_str = format_annotator_labels(c.annotator_labels)
      buf.write_string("  - ID: `\{c.sample_id}` | 严重度: `\{c.conflict_severity}` | 文本概览: `\"\{c.text}\"` | 各方标注: `\{lbl_str}`\n")
    }
    buf.write_string("\n")
  }

  let outliers = @quality.detect_schema_and_length_outliers(dataset, min_length=2, max_length=1000)
  buf.write_string("### 4.3 Schema 规范性与长度异常 (Schema & Length Outliers)\n")
  if outliers.length() == 0 {
    buf.write_string("- ✅ 样本长度均处于正常阈值范围 [2, 1000] 且所有标注类别均属于 Schema 定义列表。\n")
  } else {
    buf.write_string("- ❌ **检测到 `\{outliers.length()}` 项规范异常**:\n")
    for o in outliers {
      buf.write_string("  - 样本ID: `\{o.sample_id}` | 异常类型: `\{o.issue_type}` | 详细描述: \{o.description}\n")
    }
  }
  buf.write_string("\n---\n*Report auto-generated by MoonLabelKit v0.1.0 Data Governance Engine*\n")
  buf.to_string()
}
