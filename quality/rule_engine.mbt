///|
/// A machine-readable rule violation for CI and downstream applications.
pub(all) struct RuleViolation {
  rule : String
  sample_id : String
  message : String
  blocking : Bool
} derive(Eq, Debug)

///|
/// Configuration for the built-in dataset safety rules.
pub(all) struct RuleConfig {
  require_annotations : Bool
  require_non_empty_text : Bool
  require_unique_ids : Bool
  minimum_text_length : Int
  maximum_text_length : Int
} derive(Eq, Debug)

///|
/// Conservative defaults suitable for a training-data release gate.
pub fn default_rule_config() -> RuleConfig {
  {
    require_annotations: true,
    require_non_empty_text: true,
    require_unique_ids: true,
    minimum_text_length: 1,
    maximum_text_length: 10000,
  }
}

///|
fn add_violation(
  output : Array[RuleViolation],
  rule : String,
  id : String,
  message : String,
  blocking : Bool,
) -> Unit {
  output.push({ rule, sample_id: id, message, blocking })
}

///|
/// Apply deterministic structural rules before statistical analysis.
pub fn run_quality_rules(
  dataset : @core.Dataset,
  config : RuleConfig,
) -> Array[RuleViolation] {
  let output = []
  let seen : Map[String, Bool] = {}
  for sample in dataset.samples {
    if config.require_unique_ids && seen.contains(sample.id) {
      add_violation(
        output,
        "UniqueSampleId",
        sample.id,
        "duplicate sample id",
        true,
      )
    }
    seen[sample.id] = true
    let text_length = sample.text[:].trim().length()
    if config.require_non_empty_text && text_length < config.minimum_text_length {
      add_violation(
        output,
        "TextLength",
        sample.id,
        "text is shorter than configured minimum",
        true,
      )
    }
    if text_length > config.maximum_text_length {
      add_violation(
        output,
        "TextLength",
        sample.id,
        "text exceeds configured maximum",
        true,
      )
    }
    if config.require_annotations && sample.annotations.length() == 0 {
      add_violation(
        output,
        "AnnotationPresence",
        sample.id,
        "sample has no annotations",
        true,
      )
    }
    let labels = sample.extract_category_labels()
    let allowed : Map[String, Bool] = {}
    for label in dataset.schema_labels {
      allowed[label] = true
    }
    for label in labels {
      if dataset.schema_labels.length() > 0 && !allowed.contains(label) {
        add_violation(
          output,
          "SchemaLabel",
          sample.id,
          "label is outside the dataset schema",
          true,
        )
      }
    }
  }
  output
}

///|
/// Count blocking findings for a release decision.
pub fn blocking_violation_count(violations : Array[RuleViolation]) -> Int {
  let mut count = 0
  for violation in violations {
    if violation.blocking {
      count += 1
    }
  }
  count
}

///|
/// Count violations by rule name for a compact report.
pub fn violation_counts(violations : Array[RuleViolation]) -> Map[String, Int] {
  let counts : Map[String, Int] = {}
  for violation in violations {
    let current = match counts.get(violation.rule) {
      Some(value) => value
      None => 0
    }
    counts[violation.rule] = current + 1
  }
  counts
}

///|
/// True when no blocking structural issue remains.
pub fn passes_quality_rules(violations : Array[RuleViolation]) -> Bool {
  blocking_violation_count(violations) == 0
}
