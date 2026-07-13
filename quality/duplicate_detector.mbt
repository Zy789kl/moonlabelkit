///|
/// 重复样本检测报告条目
pub(all) struct DuplicateGroup {
  normalized_text : String
  sample_ids : Array[String]
  has_conflicting_labels : Bool
  unique_labels : Array[String]
} derive(Eq, Debug)

///|
/// 检测数据集内的重复文本样本及其标签冲突状态
pub fn detect_duplicate_samples(
  dataset : @core.Dataset,
) -> Array[DuplicateGroup] {
  // 文本归一化为小写并去首尾空格
  let text_to_samples : Map[String, Array[@core.Sample]] = {}

  for sample in dataset.samples {
    let norm = sample.text[:].trim().to_owned()
    let arr = match text_to_samples.get(norm) {
      Some(list) => list
      None => {
        let list = []
        text_to_samples[norm] = list
        list
      }
    }
    arr.push(sample)
  }

  let duplicates = []
  for norm, samples in text_to_samples {
    if samples.length() > 1 {
      let ids = []
      let label_set : Map[String, Bool] = {}
      for s in samples {
        ids.push(s.id)
        for lbl in s.extract_category_labels() {
          label_set[lbl] = true
        }
      }
      let unique_labels = []
      for l, _ in label_set {
        unique_labels.push(l)
      }
      let has_conflict = unique_labels.length() > 1
      duplicates.push({
        normalized_text: norm,
        sample_ids: ids,
        has_conflicting_labels: has_conflict,
        unique_labels,
      })
    }
  }
  duplicates
}
