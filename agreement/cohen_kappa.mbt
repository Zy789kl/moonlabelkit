///|
/// Cohen's Kappa 评估结果与一致性解释
pub(all) struct CohenKappaResult {
  annotator_a : String
  annotator_b : String
  sample_count : Int
  observed_agreement : Double
  expected_agreement : Double
  kappa_score : Double
  interpretation : String
} derive(Eq, Debug)

///|
/// 将数值型 Kappa 分数转化为标准的一致性解释说明文本 (Landis and Koch, 1977)
pub fn interpret_kappa(score : Double) -> String {
  if score < 0.0 {
    "Poor (Slight Disagreement / Negative Agreement)"
  } else if score <= 0.20 {
    "Slight Agreement"
  } else if score <= 0.40 {
    "Fair Agreement"
  } else if score <= 0.60 {
    "Moderate Agreement"
  } else if score <= 0.80 {
    "Substantial Agreement"
  } else {
    "Almost Perfect / Excellent Agreement"
  }
}

///|
/// 计算两位标注者之间的 Cohen's Kappa 一致性系数
pub fn compute_cohen_kappa(
  dataset : @core.Dataset,
  annotator_a : String,
  annotator_b : String
) -> CohenKappaResult raise @core.GovernanceError {
  let categories = dataset.schema_labels
  if categories.length() < 2 {
    raise @core.GovernanceError::ComputationError(
      "Cohen's Kappa requires at least 2 categories defined in schema"
    )
  }

  // 构建混淆矩阵类别映射
  let cat_to_idx : Map[String, Int] = {}
  let mut idx = 0
  for cat in categories {
    cat_to_idx[cat] = idx
    idx += 1
  }

  let k = categories.length()
  // 二维混淆矩阵（以一维数组存储：matrix[r * k + c]）
  let matrix = Array::make(k * k, 0)
  let mut common_samples = 0

  for sample in dataset.samples {
    let mut label_a : String? = None
    let mut label_b : String? = None

    for ann in sample.annotations {
      if ann.annotator_id == annotator_a {
        match ann.label {
          Single(l) => label_a = Some(l)
          _ => ()
        }
      } else if ann.annotator_id == annotator_b {
        match ann.label {
          Single(l) => label_b = Some(l)
          _ => ()
        }
      }
    }

    match (label_a, label_b) {
      (Some(la), Some(lb)) =>
        match (cat_to_idx.get(la), cat_to_idx.get(lb)) {
          (Some(ia), Some(ib)) => {
            matrix[ia * k + ib] = matrix[ia * k + ib] + 1
            common_samples += 1
          }
          _ => ()
        }
      _ => ()
    }
  }

  if common_samples == 0 {
    return {
      annotator_a,
      annotator_b,
      sample_count: 0,
      observed_agreement: 0.0,
      expected_agreement: 0.0,
      kappa_score: 0.0,
      interpretation: "No Common Samples",
    }
  }

  let n_f = common_samples.to_double()
  let mut observed_correct = 0
  for i = 0; i < k; i = i + 1 {
    observed_correct += matrix[i * k + i]
  }
  let p_o = observed_correct.to_double() / n_f

  let mut p_e = 0.0
  for i = 0; i < k; i = i + 1 {
    let mut row_sum = 0
    let mut col_sum = 0
    for j = 0; j < k; j = j + 1 {
      row_sum += matrix[i * k + j]
      col_sum += matrix[j * k + i]
    }
    p_e += (row_sum.to_double() * col_sum.to_double()) / (n_f * n_f)
  }

  let kappa = if (1.0 - p_e).abs() < 0.000000001 {
    if (p_o - 1.0).abs() < 0.000000001 {
      1.0
    } else {
      0.0
    }
  } else {
    (p_o - p_e) / (1.0 - p_e)
  }

  {
    annotator_a,
    annotator_b,
    sample_count: common_samples,
    observed_agreement: p_o,
    expected_agreement: p_e,
    kappa_score: kappa,
    interpretation: interpret_kappa(kappa),
  }
}
