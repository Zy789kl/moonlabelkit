///|
/// 质量异常样本/超出规范定义的标签检测报告条目
pub(all) struct OutlierReport {
  sample_id : String
  issue_type : String
  description : String
  invalid_labels : Array[String]
} derive(Eq, Debug)

///|
/// 检测数据集内超出限定 Schema 的非法类别和极端文本长度异常
pub fn detect_schema_and_length_outliers(
  dataset : @core.Dataset,
  min_length~ : Int = 2,
  max_length~ : Int = 10000
) -> Array[OutlierReport] {
  let valid_set : Map[String, Bool] = {}
  for lbl in dataset.schema_labels {
    valid_set[lbl] = true
  }

  let reports = []
  let has_schema_filter = dataset.schema_labels.length() > 0

  for sample in dataset.samples {
    let text_len = sample.text[:].trim().length()
    if text_len < min_length {
      reports.push({
        sample_id: sample.id,
        issue_type: "TextTooShort",
        description: "Sample text length (\{text_len}) is below minimum required threshold (\{min_length})",
        invalid_labels: [],
      })
    } else if text_len > max_length {
      reports.push({
        sample_id: sample.id,
        issue_type: "TextTooLong",
        description: "Sample text length (\{text_len}) exceeds maximum allowed threshold (\{max_length})",
        invalid_labels: [],
      })
    }

    if has_schema_filter {
      let invalid_in_sample = []
      for lbl in sample.extract_category_labels() {
        match valid_set.get(lbl) {
          None => invalid_in_sample.push(lbl)
          _ => ()
        }
      }
      if invalid_in_sample.length() > 0 {
        reports.push({
          sample_id: sample.id,
          issue_type: "OutOfSchemaLabel",
          description: "Found labels not defined in official dataset schema",
          invalid_labels: invalid_in_sample,
        })
      }
    }
  }
  reports
}
