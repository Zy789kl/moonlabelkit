///|
/// 单个样本的多标注冲突评估报告
pub(all) struct LabelConflictItem {
  sample_id : String
  text : String
  annotator_labels : Map[String, Array[String]]
  distinct_label_count : Int
  conflict_severity : String
} derive(Eq, Debug)

///|
/// 检测多标注数据集中样本自身的标签冲突与歧义情况
pub fn detect_label_conflicts(
  dataset : @core.Dataset,
) -> Array[LabelConflictItem] {
  let conflicts = []

  for sample in dataset.samples {
    if sample.annotations.length() > 1 {
      let ann_map : Map[String, Array[String]] = {}
      let distinct_set : Map[String, Bool] = {}

      for ann in sample.annotations {
        let labels = match ann.label {
          Single(l) => [l]
          Multi(arr) => arr
          Spans(arr) => {
            let out = []
            for s in arr {
              out.push(s.label)
            }
            out
          }
          Scores(map) => {
            let out = []
            for k, _ in map {
              out.push(k)
            }
            out
          }
        }
        ann_map[ann.annotator_id] = labels
        for l in labels {
          distinct_set[l] = true
        }
      }

      let distinct_cnt = distinct_set.length()
      if distinct_cnt > 1 {
        let severity = if distinct_cnt >= sample.annotations.length() &&
          distinct_cnt > 2 {
          "High (Severe Divergence)"
        } else if distinct_cnt == 2 {
          "Moderate (Binary Disagreement)"
        } else {
          "Low (Minor Variation)"
        }

        conflicts.push({
          sample_id: sample.id,
          text: sample.text,
          annotator_labels: ann_map,
          distinct_label_count: distinct_cnt,
          conflict_severity: severity,
        })
      }
    }
  }
  conflicts
}
