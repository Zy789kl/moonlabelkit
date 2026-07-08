///|
/// Fleiss' Kappa 多标注者一致性分析结构
pub(all) struct FleissKappaResult {
  sample_count : Int
  avg_annotators_per_sample : Double
  observed_agreement : Double
  expected_agreement : Double
  kappa_score : Double
  interpretation : String
} derive(Eq, Debug)

///|
/// 计算数据集内多位标注者之间的 Fleiss' Kappa 一致性系数
pub fn compute_fleiss_kappa(dataset : @core.Dataset) -> FleissKappaResult raise @core.GovernanceError {
  let categories = dataset.schema_labels
  if categories.length() < 2 {
    raise @core.GovernanceError::ComputationError(
      "Fleiss' Kappa requires at least 2 categories defined in schema"
    )
  }

  let cat_to_idx : Map[String, Int] = {}
  let mut idx = 0
  for cat in categories {
    cat_to_idx[cat] = idx
    idx += 1
  }
  let k = categories.length()

  let mut valid_samples = 0
  let mut total_ratings = 0
  let mut sum_p_i = 0.0
  let cat_totals = Array::make(k, 0)

  for sample in dataset.samples {
    let counts = Array::make(k, 0)
    let mut n_i = 0
    for ann in sample.annotations {
      match ann.label {
        Single(lbl) =>
          match cat_to_idx.get(lbl) {
            Some(ci) => {
              counts[ci] = counts[ci] + 1
              n_i += 1
            }
            _ => ()
          }
        _ => ()
      }
    }

    if n_i >= 2 {
      valid_samples += 1
      total_ratings += n_i
      let mut pair_matches = 0
      for j = 0; j < k; j = j + 1 {
        let cnt = counts[j]
        pair_matches += cnt * (cnt - 1)
        cat_totals[j] = cat_totals[j] + cnt
      }
      let p_i = pair_matches.to_double() / (n_i.to_double() * (n_i.to_double() - 1.0))
      sum_p_i += p_i
    }
  }

  if valid_samples == 0 {
    return {
      sample_count: 0,
      avg_annotators_per_sample: 0.0,
      observed_agreement: 0.0,
      expected_agreement: 0.0,
      kappa_score: 0.0,
      interpretation: "No Multi-Annotated Samples",
    }
  }

  let p_o = sum_p_i / valid_samples.to_double()
  let total_r_f = total_ratings.to_double()
  let mut p_e = 0.0
  for j = 0; j < k; j = j + 1 {
    let p_j = cat_totals[j].to_double() / total_r_f
    p_e += p_j * p_j
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

  let avg_ann = total_ratings.to_double() / valid_samples.to_double()

  {
    sample_count: valid_samples,
    avg_annotators_per_sample: avg_ann,
    observed_agreement: p_o,
    expected_agreement: p_e,
    kappa_score: kappa,
    interpretation: interpret_kappa(kappa),
  }
}
