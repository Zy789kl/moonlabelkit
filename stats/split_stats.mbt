///|
/// Per-split coverage metrics useful for detecting train/test leakage.
pub(all) struct SplitStats {
  split : String
  samples : Int
  annotations : Int
  unique_texts : Int
  empty_texts : Int
  average_text_length : Double
} derive(Eq, Debug)

///|
/// Build deterministic statistics for one named split.
pub fn compute_split_stats(
  dataset : @core.Dataset,
  split : String,
) -> SplitStats {
  let seen : Map[String, Bool] = Map([])
  let mut samples = 0
  let mut annotations = 0
  let mut empty = 0
  let mut total_length = 0
  for sample in dataset.samples {
    if sample.split == split {
      samples += 1
      annotations += sample.annotations.length()
      let text = sample.text[:].trim().to_owned()
      total_length += text.length()
      if text == "" {
        empty += 1
      }
      seen[text] = true
    }
  }
  let average = if samples == 0 {
    0.0
  } else {
    total_length.to_double() / samples.to_double()
  }
  {
    split,
    samples,
    annotations,
    unique_texts: seen.length(),
    empty_texts: empty,
    average_text_length: average,
  }
}

///|
/// Return the proportion of repeated text across two splits.
pub fn cross_split_duplicate_rate(
  dataset : @core.Dataset,
  left : String,
  right : String,
) -> Double {
  let right_texts : Map[String, Bool] = Map([])
  for sample in dataset.samples {
    if sample.split == right {
      right_texts[sample.text[:].trim().to_owned()] = true
    }
  }
  let mut left_count = 0
  let mut duplicate_count = 0
  for sample in dataset.samples {
    if sample.split == left {
      left_count += 1
      if right_texts.contains(sample.text[:].trim().to_owned()) {
        duplicate_count += 1
      }
    }
  }
  if left_count == 0 {
    0.0
  } else {
    duplicate_count.to_double() / left_count.to_double()
  }
}

///|
/// A leakage threshold suitable for a conservative data gate.
pub fn has_split_leakage(rate : Double, threshold? : Double = 0.0) -> Bool {
  rate > threshold
}
