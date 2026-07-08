///|
test "detect duplicate samples and conflicting labels" {
  let ds = @core.Dataset::new("dup_test", @core.TaskType::Classification, ["Pos", "Neg"])
  let s1 = @core.Sample::create_simple("id_1", "  Same text  ", "Pos")
  let s2 = @core.Sample::create_simple("id_2", "Same text", "Neg")
  let s3 = @core.Sample::create_simple("id_3", "Unique text", "Pos")
  ds.add_sample(s1)
  ds.add_sample(s2)
  ds.add_sample(s3)

  let dups = detect_duplicate_samples(ds)
  inspect(dups.length(), content="1")
  inspect(dups[0].has_conflicting_labels, content="true")
  inspect(dups[0].sample_ids.length(), content="2")
}

///|
test "detect multi-annotator within-sample label conflicts" {
  let ds = @core.Dataset::new("conf_test", @core.TaskType::Classification, ["Pos", "Neg"])
  let s = @core.Sample::create_simple("s1", "Ambiguous text", "Pos", annotator="alice")
  s.annotations.push({ annotator_id: "bob", label: Single("Neg"), timestamp: 0L, confidence: None })
  ds.add_sample(s)

  let confs = detect_label_conflicts(ds)
  inspect(confs.length(), content="1")
  inspect(confs[0].distinct_label_count, content="2")
  inspect(confs[0].conflict_severity, content="Moderate (Binary Disagreement)")
}

///|
test "detect length outliers and schema violations" {
  let ds = @core.Dataset::new("out_test", @core.TaskType::Classification, ["Valid_A", "Valid_B"])
  let s_short = @core.Sample::create_simple("short_1", "x", "Valid_A")
  let s_bad_lbl = @core.Sample::create_simple("bad_1", "Normally sized text.", "Illegal_Label")
  ds.add_sample(s_short)
  ds.add_sample(s_bad_lbl)

  let reports = detect_schema_and_length_outliers(ds, min_length=3, max_length=100)
  inspect(reports.length(), content="2")
}
