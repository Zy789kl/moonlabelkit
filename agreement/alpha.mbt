///|
/// Krippendorff's Alpha 一致性分析结构
pub(all) struct KrippendorffAlphaResult {
  sample_count : Int
  avg_annotators_per_sample : Double
  observed_disagreement : Double
  expected_disagreement : Double
  alpha_score : Double
  interpretation : String
} derive(Eq, Debug)

///|
/// 计算数据集内多位标注者之间的 Krippendorff's Alpha 一致性系数 (Nominal Data)
/// Alpha = 1 - (D_o / D_e)
pub fn compute_krippendorff_alpha(
  dataset : @core.Dataset,
) -> KrippendorffAlphaResult raise @core.GovernanceError {
  let categories = dataset.schema_labels
  if categories.length() < 2 {
    raise @core.GovernanceError::ComputationError(
      "Krippendorff's Alpha requires at least 2 categories defined in schema",
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
  let mut total_pairable_ratings = 0
  let mut d_o_sum = 0.0

  let global_cat_totals = Array::make(k, 0.0)

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
      total_pairable_ratings += n_i

      let mut pairs = 0.0
      for j = 0; j < k; j = j + 1 {
        let cnt = counts[j].to_double()
        global_cat_totals[j] = global_cat_totals[j] + cnt
        for c = 0; c < k; c = c + 1 {
          if j != c {
            let cnt_c = counts[c].to_double()
            pairs += cnt * cnt_c
          }
        }
      }
      // D_o component for this sample is pairs / (n_i - 1)
      d_o_sum += pairs / (n_i.to_double() - 1.0)
    }
  }

  if valid_samples == 0 {
    return {
      sample_count: 0,
      avg_annotators_per_sample: 0.0,
      observed_disagreement: 0.0,
      expected_disagreement: 0.0,
      alpha_score: 0.0,
      interpretation: "No Multi-Annotated Samples",
    }
  }

  let total_n = total_pairable_ratings.to_double()
  let d_o = d_o_sum / total_n

  let mut d_e_sum = 0.0
  for j = 0; j < k; j = j + 1 {
    let n_c = global_cat_totals[j]
    for c = 0; c < k; c = c + 1 {
      if j != c {
        let n_k = global_cat_totals[c]
        d_e_sum += n_c * n_k
      }
    }
  }
  let d_e = d_e_sum / (total_n * (total_n - 1.0))

  let alpha = if d_e < 0.000000001 {
    if d_o < 0.000000001 {
      1.0
    } else {
      0.0
    }
  } else {
    1.0 - d_o / d_e
  }

  let avg_ann = total_n / valid_samples.to_double()

  {
    sample_count: valid_samples,
    avg_annotators_per_sample: avg_ann,
    observed_disagreement: d_o,
    expected_disagreement: d_e,
    alpha_score: alpha,
    interpretation: interpret_kappa(alpha),
  }
}
