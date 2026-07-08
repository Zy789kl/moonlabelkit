///|
/// 多位标注者两两一致性评估条目
pub(all) struct PairwiseAgreementSummary {
  annotator_a : String
  annotator_b : String
  common_samples : Int
  kappa : Double
  interpretation : String
} derive(Eq, Debug)

///|
/// 获取数据集中所有标注者两两配对的一致性评估汇总矩阵
pub fn compute_pairwise_agreement_matrix(
  dataset : @core.Dataset
) -> Array[PairwiseAgreementSummary] {
  let annotators = dataset.get_all_annotators()
  let results = []
  let n = annotators.length()

  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      let a = annotators[i]
      let b = annotators[j]
      let res = try {
        compute_cohen_kappa(dataset, a, b)
      } catch {
        _ => continue
      }
      results.push({
        annotator_a: a,
        annotator_b: b,
        common_samples: res.sample_count,
        kappa: res.kappa_score,
        interpretation: res.interpretation,
      })
    }
  }
  results
}
