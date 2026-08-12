///|
test "summary reports splits, coverage and annotators" {
  let dataset = Dataset::new("summary", TaskType::Classification, ["yes", "no"])
  let labeled = Sample::create_simple("a", "one", "yes", split="train")
  let unlabeled : Sample = {
    id: "b",
    text: "two",
    metadata: {},
    annotations: [],
    split: "test",
  }
  dataset.add_sample(labeled)
  dataset.add_sample(unlabeled)
  let summary = summarize_dataset(dataset)
  inspect(summary.sample_count, content="2")
  inspect(summary.annotation_count, content="1")
  inspect(summary.unlabeled_sample_count, content="1")
  inspect(annotation_coverage(summary), content="0.5")
  inspect(has_required_splits(summary, ["train", "test"]), content="true")
  inspect(has_required_splits(summary, ["dev"]), content="false")
}

///|
test "summary handles an entirely empty dataset" {
  let dataset = Dataset::new("none", TaskType::Classification, [])
  let summary = summarize_dataset(dataset)
  inspect(summary.sample_count, content="0")
  inspect(summary.annotation_count, content="0")
  inspect(summary.annotator_count, content="0")
  inspect(summary.labeled_sample_count, content="0")
  inspect(summary.unlabeled_sample_count, content="0")
  inspect(annotation_coverage(summary), content="0")
  inspect(has_required_splits(summary, []), content="true")
}

///|
test "summary counts multiple annotations for one sample" {
  let dataset = Dataset::new("multi", Classification, ["yes"])
  let sample = Sample::create_simple("a", "text", "yes", annotator="one")
  sample.annotations.push({
    annotator_id: "two",
    label: LabelValue::Single("yes"),
    timestamp: 0L,
    confidence: Some(0.9),
  })
  dataset.add_sample(sample)
  let summary = summarize_dataset(dataset)
  inspect(summary.sample_count, content="1")
  inspect(summary.annotation_count, content="2")
  inspect(summary.annotator_count, content="2")
  inspect(annotation_coverage(summary), content="1")
  inspect(split_count(summary, "train"), content="1")
  inspect(split_count(summary, "dev"), content="0")
  inspect(annotation_density(summary), content="2")
  inspect(is_empty(summary), content="false")
  inspect(is_fully_annotated(summary), content="true")
  inspect(text_uniqueness_ratio(summary, 1), content="1")
  inspect(passes_basic_coverage(summary), content="true")
}
