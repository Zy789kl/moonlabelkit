///|
/// Quality gate result used by batch pipelines and CI integrations.
pub(all) enum QualityLevel {
  Pass
  Review
  Reject
} derive(Eq, Debug)

///|
/// A deterministic, explainable quality score for one dataset.
pub(all) struct QualityScore {
  sample_count : Int
  annotation_count : Int
  duplicate_groups : Int
  conflict_samples : Int
  invalid_samples : Int
  score : Double
  level : QualityLevel
  reasons : Array[String]
} derive(Eq, Debug)

///|
fn clamp_score(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 100.0 {
    100.0
  } else {
    value
  }
}

///|
fn level_for(score : Double, invalid : Int, conflicts : Int) -> QualityLevel {
  if invalid > 0 || score < 50.0 {
    Reject
  } else if conflicts > 0 || score < 80.0 {
    Review
  } else {
    Pass
  }
}

///|
fn add_reason(reasons : Array[String], message : String) -> Unit {
  reasons.push(message)
}

///|
/// Convert detector outputs into one CI-friendly quality gate.
pub fn compute_quality_score(
  dataset : @core.Dataset,
  duplicate_groups : Int,
  conflict_samples : Int,
  invalid_samples : Int,
) -> QualityScore {
  let mut annotations = 0
  for sample in dataset.samples {
    annotations += sample.annotations.length()
  }
  let sample_count = dataset.samples.length()
  let mut score = 100.0
  let reasons = []
  if sample_count == 0 {
    score = 0.0
    add_reason(reasons, "dataset is empty")
  }
  if duplicate_groups > 0 {
    score -= (duplicate_groups * 5).to_double()
    add_reason(reasons, "duplicate text groups require review")
  }
  if conflict_samples > 0 {
    score -= (conflict_samples * 8).to_double()
    add_reason(reasons, "annotator conflicts require adjudication")
  }
  if invalid_samples > 0 {
    score -= (invalid_samples * 15).to_double()
    add_reason(reasons, "schema or boundary violations must be fixed")
  }
  if annotations == 0 && sample_count > 0 {
    score -= 20.0
    add_reason(reasons, "samples have no annotations")
  }
  let final_score = clamp_score(score)
  {
    sample_count,
    annotation_count: annotations,
    duplicate_groups,
    conflict_samples,
    invalid_samples,
    score: final_score,
    level: level_for(final_score, invalid_samples, conflict_samples),
    reasons,
  }
}

///|
/// Whether a score is safe to use as an automated release gate.
pub fn is_release_ready(result : QualityScore) -> Bool {
  match result.level {
    Pass => result.invalid_samples == 0 && result.score >= 80.0
    _ => false
  }
}

///|
/// Human-readable action for dashboards and generated reports.
pub fn recommended_action(result : QualityScore) -> String {
  match result.level {
    Pass => "publish or continue to model training"
    Review => "route flagged records to human adjudication"
    Reject => "stop the pipeline and repair the dataset"
  }
}
