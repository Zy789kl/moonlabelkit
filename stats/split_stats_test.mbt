///|
test "split metrics expose coverage and leakage" {
  let dataset = @core.Dataset::new("splits", @core.TaskType::Classification, [
    "yes",
  ])
  dataset.add_sample(
    @core.Sample::create_simple("a", "same", "yes", split="train"),
  )
  dataset.add_sample(
    @core.Sample::create_simple("b", "same", "yes", split="test"),
  )
  dataset.add_sample(
    @core.Sample::create_simple("c", "only train", "yes", split="train"),
  )
  let train = compute_split_stats(dataset, "train")
  inspect(train.samples, content="2")
  inspect(train.unique_texts, content="2")
  inspect(cross_split_duplicate_rate(dataset, "train", "test"), content="0.5")
  inspect(has_split_leakage(0.5), content="true")
  inspect(has_split_leakage(0.0), content="false")
}

///|
test "split metrics handle missing and empty splits" {
  let dataset = @core.Dataset::new(
    "empty-splits",
    @core.TaskType::Classification,
    ["yes"],
  )
  let empty = compute_split_stats(dataset, "dev")
  inspect(empty.samples, content="0")
  inspect(empty.annotations, content="0")
  inspect(empty.average_text_length, content="0")
  inspect(cross_split_duplicate_rate(dataset, "train", "test"), content="0")
  inspect(has_split_leakage(0.1, threshold=0.2), content="false")
}

///|
test "split stats preserve separate text keys" {
  let dataset = @core.Dataset::new("keys", @core.TaskType::Classification, [
    "yes",
  ])
  dataset.add_sample(
    @core.Sample::create_simple("a", "same", "yes", split="train"),
  )
  dataset.add_sample(
    @core.Sample::create_simple("b", "same ", "yes", split="train"),
  )
  let stats = compute_split_stats(dataset, "train")
  inspect(stats.unique_texts, content="1")
  inspect(stats.average_text_length, content="4")
}
