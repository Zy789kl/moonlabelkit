///|
test "sequence boundary validation catches range, overlap and text mismatch" {
  let dataset = @core.Dataset::new("spans", @core.TaskType::SequenceLabeling, [
    "ORG",
  ])
  let sample = @core.Sample::create_sequence("s1", "MoonBit ships", [
    { start: 0, end: 7, label: "ORG", text: "MoonBit" },
    { start: 6, end: 12, label: "ORG", text: "it ship" },
    { start: 20, end: 21, label: "ORG", text: "x" },
  ])
  dataset.add_sample(sample)
  let issues = validate_sequence_boundaries(dataset)
  inspect(issues.length(), content="3")
  inspect(count_errors(issues), content="2")
  inspect(is_structurally_valid(issues), content="false")
}

///|
test "empty sequence dataset is structurally valid" {
  let dataset = @core.Dataset::new("empty", @core.TaskType::SequenceLabeling, [
    "ORG",
  ])
  let issues = validate_sequence_boundaries(dataset)
  inspect(issues.length(), content="0")
  inspect(is_structurally_valid(issues), content="true")
}

///|
test "boundary validator accepts adjacent spans and catches mismatched text" {
  let dataset = @core.Dataset::new(
    "adjacent",
    @core.TaskType::SequenceLabeling,
    ["A"],
  )
  let sample = @core.Sample::create_sequence("s2", "abcdef", [
    { start: 0, end: 3, label: "A", text: "abc" },
    { start: 3, end: 6, label: "A", text: "bad" },
  ])
  dataset.add_sample(sample)
  let issues = validate_sequence_boundaries(dataset)
  inspect(issues.length(), content="1")
  inspect(issues[0].code, content="TextMismatch")
  inspect(count_errors(issues), content="1")
}

///|
test "boundary validator ignores classification annotations" {
  let dataset = @core.Dataset::new(
    "classification",
    @core.TaskType::Classification,
    ["A"],
  )
  dataset.add_sample(@core.Sample::create_simple("c1", "plain text", "A"))
  let issues = validate_sequence_boundaries(dataset)
  inspect(issues.length(), content="0")
  inspect(is_structurally_valid(issues), content="true")
}
