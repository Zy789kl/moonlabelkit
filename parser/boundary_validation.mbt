///|
/// A single structural issue found after parsing a dataset.
pub(all) struct BoundaryIssue {
  sample_id : String
  code : String
  message : String
  severity : String
} derive(Eq, Debug)

///|
/// Validate sequence spans against UTF-8-safe string boundaries used by MoonBit.
pub fn validate_sequence_boundaries(
  dataset : @core.Dataset,
) -> Array[BoundaryIssue] {
  let issues = []
  for sample in dataset.samples {
    for annotation in sample.annotations {
      match annotation.label {
        @core.LabelValue::Spans(spans) => {
          let mut previous_end = 0
          for span in spans {
            if span.start < 0 || span.end <= span.start {
              issues.push({
                sample_id: sample.id,
                code: "InvalidRange",
                message: "span must satisfy 0 <= start < end",
                severity: "error",
              })
            } else if span.end > sample.text.length() {
              issues.push({
                sample_id: sample.id,
                code: "OutOfBounds",
                message: "span end exceeds text length",
                severity: "error",
              })
            } else if span.start < previous_end {
              issues.push({
                sample_id: sample.id,
                code: "Overlap",
                message: "spans overlap or are not ordered",
                severity: "warning",
              })
            }
            if span.end > previous_end {
              previous_end = span.end
            }
            if span.text != "" && span.end <= sample.text.length() {
              let actual = sample.text[span.start:span.end].to_owned()
              if actual != span.text {
                issues.push({
                  sample_id: sample.id,
                  code: "TextMismatch",
                  message: "span text does not match source text",
                  severity: "error",
                })
              }
            }
          }
        }
        _ => ()
      }
    }
  }
  issues
}

///|
/// Count issues by severity for release dashboards.
pub fn count_errors(issues : Array[BoundaryIssue]) -> Int {
  let mut result = 0
  for issue in issues {
    if issue.severity == "error" {
      result += 1
    }
  }
  result
}

///|
/// A dataset passes structural validation only when no errors exist.
pub fn is_structurally_valid(issues : Array[BoundaryIssue]) -> Bool {
  count_errors(issues) == 0
}
