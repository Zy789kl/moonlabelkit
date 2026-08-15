///|
/// 标签分布统计与不平衡度衡量结果指标
pub(all) struct LabelDistribution {
  total_annotations : Int
  frequency : Map[String, Int]
  proportions : Map[String, Double]
  shannon_entropy : Double
  gini_imbalance : Double
  max_min_ratio : Double
} derive(Eq, Debug)

///|
/// 针对整个数据集计算详细的类别分布统计与信息熵指数
pub fn compute_label_distribution(dataset : @core.Dataset) -> LabelDistribution {
  let freq : Map[String, Int] = {}
  let mut total = 0

  for sample in dataset.samples {
    let labels = sample.extract_category_labels()
    for lbl in labels {
      let cur = match freq.get(lbl) {
        Some(c) => c
        None => 0
      }
      freq[lbl] = cur + 1
      total += 1
    }
  }

  let props : Map[String, Double] = {}
  let mut entropy = 0.0
  let mut max_cnt = 0
  let mut min_cnt = -1

  if total > 0 {
    let total_f = total.to_double()
    for k, v in freq {
      let p = v.to_double() / total_f
      props[k] = p
      if p > 0.0 {
        // 使用底数为2的信息熵（比特）
        let ln2 = 0.6931471805599453
        let log2_p = @math.ln(p) / ln2
        entropy -= p * log2_p
      }
      if v > max_cnt {
        max_cnt = v
      }
      if min_cnt == -1 || v < min_cnt {
        min_cnt = v
      }
    }
  }

  // This is the Gini inequality coefficient, not Gini impurity.
  // Keeping the pairwise definition makes the reported metric agree with
  // docs/THEORY.md and keeps 0.0 as the exact value for a balanced dataset.
  let counts = []
  for _, count in freq {
    counts.push(count)
  }
  let mut pairwise_difference = 0.0
  for i = 0; i < counts.length(); i = i + 1 {
    for j = 0; j < counts.length(); j = j + 1 {
      pairwise_difference += (counts[i] - counts[j]).abs().to_double()
    }
  }
  let gini = if total > 0 && counts.length() > 0 {
    pairwise_difference /
    (2.0 * counts.length().to_double() * total.to_double())
  } else {
    0.0
  }
  let ratio = if min_cnt > 0 {
    max_cnt.to_double() / min_cnt.to_double()
  } else if max_cnt > 0 {
    max_cnt.to_double()
  } else {
    0.0
  }

  {
    total_annotations: total,
    frequency: freq,
    proportions: props,
    shannon_entropy: entropy,
    gini_imbalance: gini,
    max_min_ratio: ratio,
  }
}

///|
/// 检查数据集是否存在严重的类别极端不平衡（比例超过阈值如 10.0）
pub fn is_severely_imbalanced(
  dist : LabelDistribution,
  threshold? : Double = 10.0,
) -> Bool {
  dist.max_min_ratio >= threshold && dist.frequency.length() > 1
}
