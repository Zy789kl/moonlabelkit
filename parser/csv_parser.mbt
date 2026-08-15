///|
/// 解析 CSV 或 TSV 表格格式数据为 Dataset 实体
fn split_delimited_line(line : String, delimiter : Char) -> Array[String] {
  let fields = []
  let mut field = StringBuilder::new()
  let mut in_quotes = false
  for ch in line {
    if ch == '"' {
      in_quotes = !in_quotes
    } else if ch == delimiter && !in_quotes {
      fields.push(field.to_string().trim().to_owned())
      field = StringBuilder::new()
    } else {
      field.write_char(ch)
    }
  }
  fields.push(field.to_string().trim().to_owned())
  fields
}

///|
/// 解析 CSV 或 TSV 表格格式数据为 Dataset 实体
pub fn parse_tabular_dataset(
  content : String,
  dataset_name : String,
  schema_labels : Array[String],
  delimiter? : Char = ',',
) -> @core.Dataset raise @core.GovernanceError {
  let ds = @core.Dataset::new(
    dataset_name,
    @core.TaskType::Tabular,
    schema_labels,
  )
  let lines = content.split("\n")
  let mut is_header = true
  let mut header_cols = []
  let mut text_col_idx = -1
  let mut label_col_idx = -1
  let mut id_col_idx = -1
  let mut annotator_col_idx = -1
  let mut split_col_idx = -1
  let mut line_no = 1

  for line_view in lines {
    let line_str : String = line_view.trim().to_owned()
    if line_str != "" {
      let cols = split_delimited_line(line_str, delimiter)
      if is_header {
        header_cols = cols
        let mut idx = 0
        for col_name in header_cols {
          if col_name == "text" ||
            col_name == "content" ||
            col_name == "sentence" {
            text_col_idx = idx
          } else if col_name == "label" ||
            col_name == "category" ||
            col_name == "target" {
            label_col_idx = idx
          } else if col_name == "id" {
            id_col_idx = idx
          } else if col_name == "annotator" || col_name == "annotator_id" {
            annotator_col_idx = idx
          } else if col_name == "split" {
            split_col_idx = idx
          }
          idx += 1
        }
        if text_col_idx == -1 || label_col_idx == -1 {
          raise @core.GovernanceError::SchemaMismatch(
            "CSV header missing required 'text' or 'label' column at line \{line_no}",
          )
        }
        is_header = false
      } else {
        if cols.length() <= text_col_idx || cols.length() <= label_col_idx {
          raise @core.GovernanceError::ParserError(
            "Column count mismatch", line_no,
          )
        }
        let id = if id_col_idx >= 0 && id_col_idx < cols.length() {
          cols[id_col_idx]
        } else {
          "tab_\{line_no}"
        }
        let text = cols[text_col_idx]
        let label = cols[label_col_idx]
        let annotator = if annotator_col_idx >= 0 &&
          annotator_col_idx < cols.length() {
          cols[annotator_col_idx]
        } else {
          "default"
        }
        let split = if split_col_idx >= 0 && split_col_idx < cols.length() {
          cols[split_col_idx]
        } else {
          "train"
        }
        let sample = @core.Sample::create_simple(
          id,
          text,
          label,
          annotator~,
          split~,
        )
        ds.add_sample(sample)
      }
    }
    line_no += 1
  }
  ds
}
