///|
/// Compact coverage summary for dashboards and reproducibility reports.
pub(all) struct DatasetSummary {
  sample_count : Int
  annotation_count : Int
  annotator_count : Int
  split_counts : Map[String, Int]
  labeled_sample_count : Int
  unlabeled_sample_count : Int
} derive(Eq, Debug)

///|
/// Calculate counts without changing the source dataset.
pub fn summarize_dataset(dataset : Dataset) -> DatasetSummary {
  let splits : Map[String, Int] = Map([])
  let mut annotation_count = 0
  let mut labeled = 0
  for sample in dataset.samples {
    let old = match splits.get(sample.split) {
      Some(value) => value
      None => 0
    }
    splits[sample.split] = old + 1
    annotation_count += sample.annotations.length()
    if sample.annotations.length() > 0 {
      labeled += 1
    }
  }
  {
    sample_count: dataset.samples.length(),
    annotation_count,
    annotator_count: dataset.get_all_annotators().length(),
    split_counts: splits,
    labeled_sample_count: labeled,
    unlabeled_sample_count: dataset.samples.length() - labeled,
  }
}

///|
/// Fraction of samples that have at least one annotation.
pub fn annotation_coverage(summary : DatasetSummary) -> Double {
  if summary.sample_count == 0 {
    0.0
  } else {
    summary.labeled_sample_count.to_double() / summary.sample_count.to_double()
  }
}

///|
/// Whether every requested split exists and contains data.
pub fn has_required_splits(
  summary : DatasetSummary,
  required : Array[String],
) -> Bool {
  for split in required {
    match summary.split_counts.get(split) {
      Some(value) => if value == 0 { return false }
      None => return false
    }
  }
  true
}

///|
/// Number of samples in a named split, returning zero for an absent split.
pub fn split_count(summary : DatasetSummary, split : String) -> Int {
  match summary.split_counts.get(split) {
    Some(value) => value
    None => 0
  }
}

///|
/// Average number of annotations per sample, including zero-annotation rows.
pub fn annotation_density(summary : DatasetSummary) -> Double {
  if summary.sample_count == 0 {
    0.0
  } else {
    summary.annotation_count.to_double() / summary.sample_count.to_double()
  }
}

///|
/// Empty datasets cannot be released as training data.
pub fn is_empty(summary : DatasetSummary) -> Bool {
  summary.sample_count == 0
}

///|
/// Whether all samples have at least one annotation.
pub fn is_fully_annotated(summary : DatasetSummary) -> Bool {
  summary.sample_count > 0 && summary.unlabeled_sample_count == 0
}

///|
/// Ratio of distinct text values to samples; lower values indicate repetition.
pub fn text_uniqueness_ratio(
  summary : DatasetSummary,
  unique_texts : Int,
) -> Double {
  if summary.sample_count == 0 {
    0.0
  } else {
    unique_texts.to_double() / summary.sample_count.to_double()
  }
}

///|
/// A compact release predicate combining coverage and non-empty input checks.
pub fn passes_basic_coverage(summary : DatasetSummary) -> Bool {
  !is_empty(summary) &&
  is_fully_annotated(summary) &&
  annotation_coverage(summary) == 1.0
}

///|
/// Whether a split has at least one sample.
pub fn split_exists(summary : DatasetSummary, split : String) -> Bool {
  split_count(summary, split) > 0
}
