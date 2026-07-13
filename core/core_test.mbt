///|
test "dataset creation and sample extraction" {
  let ds = Dataset::new("text_classification_v1", TaskType::Classification, [
    "Positive", "Negative", "Neutral",
  ])
  let s1 = Sample::create_simple(
    "doc_001",
    "This product is amazing and fast!",
    "Positive",
    annotator="alice",
    split="train",
  )
  let s2 = Sample::create_simple(
    "doc_002",
    "Terrible support service.",
    "Negative",
    annotator="bob",
    split="dev",
  )
  let s3 = Sample::create_simple(
    "doc_003",
    "It works OK.",
    "Neutral",
    annotator="alice",
    split="train",
  )
  ds.add_sample(s1)
  ds.add_sample(s2)
  ds.add_sample(s3)
  inspect(ds.samples.length(), content="3")
  inspect(ds.get_all_annotators().length(), content="2")
  let train_ds = ds.filter_by_split("train")
  inspect(train_ds.samples.length(), content="2")
  debug_inspect(s1.extract_category_labels(), content="[\"Positive\"]")
}

///|
test "sequence labeling sample creation" {
  let span1 : EntitySpan = { start: 0, end: 5, label: "ORG", text: "Apple" }
  let span2 : EntitySpan = {
    start: 16,
    end: 24,
    label: "LOC",
    text: "New York",
  }
  let seq_sample = Sample::create_sequence(
    "ner_001",
    "Apple opened in New York.",
    [span1, span2],
    annotator="expert_1",
    split="test",
  )
  debug_inspect(
    seq_sample.extract_category_labels(),
    content="[\"ORG\", \"LOC\"]",
  )
}
