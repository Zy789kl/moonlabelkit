///|
/// 辅助从 JSON 对象中安全提取字符串字段
fn extract_json_string(map : Map[String, Json], key : String) -> String? {
  match map.get(key) {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some(n.to_string())
    _ => None
  }
}

///|
/// 解析单行分类标注JSON记录
pub fn parse_classification_json_line(
  line : String,
  line_no : Int,
  default_split~ : String = "train"
) -> @core.Sample raise @core.GovernanceError {
  let trimmed : String = line[:].trim().to_owned()
  if trimmed == "" {
    raise @core.GovernanceError::ParserError("Empty line", line_no)
  }
  let json = try {
    @json.parse(trimmed[:])
  } catch {
    _ => raise @core.GovernanceError::ParserError("Invalid JSON format", line_no)
  }
  match json {
    Object(map) => {
      let id = match extract_json_string(map, "id") {
        Some(s) => s
        None => "sample_\{line_no}"
      }
      let text = match extract_json_string(map, "text") {
        Some(s) => s
        None =>
          match extract_json_string(map, "content") {
            Some(c) => c
            None => raise @core.GovernanceError::ParserError("Missing text/content field", line_no)
          }
      }
      let annotator = match extract_json_string(map, "annotator") {
        Some(a) => a
        None => "default_annotator"
      }
      let split = match extract_json_string(map, "split") {
        Some(sp) => sp
        None => default_split
      }
      let label_val : @core.LabelValue = match map.get("label") {
        Some(String(l)) => Single(l)
        Some(Array(arr)) => {
          let out = []
          for item in arr {
            match item {
              String(s) => out.push(s)
              _ => ()
            }
          }
          Multi(out)
        }
        _ =>
          match map.get("labels") {
            Some(Array(arr)) => {
              let out = []
              for item in arr {
                match item {
                  String(s) => out.push(s)
                  _ => ()
                }
              }
              Multi(out)
            }
            _ => raise @core.GovernanceError::ParserError("Missing label or labels field", line_no)
          }
      }
      let ann : @core.Annotation = {
        annotator_id: annotator,
        label: label_val,
        timestamp: 0L,
        confidence: None,
      }
      { id, text, metadata: {}, annotations: [ann], split }
    }
    _ => raise @core.GovernanceError::ParserError("JSON record must be an object", line_no)
  }
}

///|
/// 解析单行序列标注（命名实体识别/区间标注）JSON记录
pub fn parse_sequence_json_line(
  line : String,
  line_no : Int,
  default_split~ : String = "train"
) -> @core.Sample raise @core.GovernanceError {
  let trimmed : String = line[:].trim().to_owned()
  if trimmed == "" {
    raise @core.GovernanceError::ParserError("Empty line", line_no)
  }
  let json = try {
    @json.parse(trimmed[:])
  } catch {
    _ => raise @core.GovernanceError::ParserError("Invalid JSON format", line_no)
  }
  match json {
    Object(map) => {
      let id = match extract_json_string(map, "id") {
        Some(s) => s
        None => "seq_\{line_no}"
      }
      let text = match extract_json_string(map, "text") {
        Some(s) => s
        None => raise @core.GovernanceError::ParserError("Missing text field", line_no)
      }
      let annotator = match extract_json_string(map, "annotator") {
        Some(a) => a
        None => "default_annotator"
      }
      let split = match extract_json_string(map, "split") {
        Some(sp) => sp
        None => default_split
      }
      let spans = []
      match map.get("spans") {
        Some(Array(arr)) =>
          for item in arr {
            match item {
              Object(span_map) => {
                let start = match span_map.get("start") {
                  Some(Number(n, ..)) => n.to_int()
                  _ => 0
                }
                let end = match span_map.get("end") {
                  Some(Number(n, ..)) => n.to_int()
                  _ => 0
                }
                let label = match extract_json_string(span_map, "label") {
                  Some(l) => l
                  None => "ENTITY"
                }
                let span_text = match extract_json_string(span_map, "text") {
                  Some(t) => t
                  None =>
                    if start >= 0 && end <= text.length() && start < end {
                      text[start:end].to_owned()
                    } else {
                      ""
                    }
                }
                let span : @core.EntitySpan = { start, end, label, text: span_text }
                spans.push(span)
              }
              _ => ()
            }
          }
        _ => raise @core.GovernanceError::ParserError("Missing spans array field", line_no)
      }
      let ann : @core.Annotation = {
        annotator_id: annotator,
        label: Spans(spans),
        timestamp: 0L,
        confidence: None,
      }
      { id, text, metadata: {}, annotations: [ann], split }
    }
    _ => raise @core.GovernanceError::ParserError("JSON record must be an object", line_no)
  }
}

///|
/// 解析完整JSONL文本至Dataset实体
pub fn parse_jsonl_dataset(
  content : String,
  dataset_name : String,
  task_type : @core.TaskType,
  schema_labels : Array[String]
) -> @core.Dataset raise @core.GovernanceError {
  let ds = @core.Dataset::new(dataset_name, task_type, schema_labels)
  let lines = content.split("\n")
  let mut line_no = 1
  for line_view in lines {
    let line_str : String = line_view.trim().to_owned()
    if line_str != "" {
      match task_type {
        Classification => {
          let sample = parse_classification_json_line(line_str, line_no)
          ds.add_sample(sample)
        }
        SequenceLabeling => {
          let sample = parse_sequence_json_line(line_str, line_no)
          ds.add_sample(sample)
        }
        _ => {
          let sample = parse_classification_json_line(line_str, line_no)
          ds.add_sample(sample)
        }
      }
    }
    line_no += 1
  }
  ds
}
