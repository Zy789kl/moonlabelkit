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
  let mut sum_sq = 0.0
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
      sum_sq += p * p
      if v > max_cnt {
        max_cnt = v
      }
      if min_cnt == -1 || v < min_cnt {
        min_cnt = v
      }
    }
  }

  let gini = if total > 0 { 1.0 - sum_sq } else { 0.0 }
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
pub fn is_severely_imbalanced(dist : LabelDistribution, threshold~ : Double = 10.0) -> Bool {
  dist.max_min_ratio >= threshold && dist.frequency.length() > 1
}
