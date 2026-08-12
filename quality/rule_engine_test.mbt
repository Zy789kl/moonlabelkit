///|
test "quality rules detect duplicate ids, empty text, missing annotations and bad labels" {
  let dataset = @core.Dataset::new("rules", @core.TaskType::Classification, [
    "ok",
  ])
  let first = @core.Sample::create_simple("same", "valid text", "ok")
  let second : @core.Sample = {
    id: "same",
    text: "",
    metadata: {},
    annotations: [],
    split: "train",
  }
  let third = @core.Sample::create_simple("bad", "valid text", "outside")
  dataset.add_sample(first)
  dataset.add_sample(second)
  dataset.add_sample(third)
  let issues = run_quality_rules(dataset, default_rule_config())
  inspect(blocking_violation_count(issues), content="4")
  inspect(passes_quality_rules(issues), content="false")
  let counts = violation_counts(issues)
  inspect(counts.contains("UniqueSampleId"), content="true")
}

///|
test "quality score is release ready only for clean data" {
  let dataset = @core.Dataset::new("clean", @core.TaskType::Classification, [
    "ok",
  ])
  dataset.add_sample(@core.Sample::create_simple("id", "valid", "ok"))
  let clean = compute_quality_score(dataset, 0, 0, 0)
  inspect(
    match clean.level {
      Pass => true
      _ => false
    },
    content="true",
  )
  inspect(is_release_ready(clean), content="true")
  let dirty = compute_quality_score(dataset, 1, 2, 0)
  inspect(
    match dirty.level {
      Review => true
      _ => false
    },
    content="true",
  )
  inspect(is_release_ready(dirty), content="false")
}

///|
test "quality rules respect configurable annotation and length policies" {
  let dataset = @core.Dataset::new("config", @core.TaskType::Classification, [
    "ok",
  ])
  dataset.add_sample({
    id: "x",
    text: "",
    metadata: {},
    annotations: [],
    split: "train",
  })
  let config : RuleConfig = {
    require_annotations: false,
    require_non_empty_text: false,
    require_unique_ids: true,
    minimum_text_length: 0,
    maximum_text_length: 10,
  }
  let issues = run_quality_rules(dataset, config)
  inspect(issues.length(), content="0")
  inspect(passes_quality_rules(issues), content="true")
}
