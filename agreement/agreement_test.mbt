///|
test "cohen kappa perfect agreement" {
  let ds = @core.Dataset::new("test_kappa", @core.TaskType::Classification, ["Yes", "No"])
  let s1 = @core.Sample::create_simple("1", "t1", "Yes", annotator="alice")
  let s1_b : @core.Annotation = { annotator_id: "bob", label: Single("Yes"), timestamp: 0L, confidence: None }
  s1.annotations.push(s1_b)

  let s2 = @core.Sample::create_simple("2", "t2", "No", annotator="alice")
  let s2_b : @core.Annotation = { annotator_id: "bob", label: Single("No"), timestamp: 0L, confidence: None }
  s2.annotations.push(s2_b)

  ds.add_sample(s1)
  ds.add_sample(s2)

  let kappa = compute_cohen_kappa(ds, "alice", "bob")
  inspect(kappa.sample_count, content="2")
  inspect(kappa.kappa_score > 0.999, content="true")
  inspect(kappa.interpretation, content="Almost Perfect / Excellent Agreement")
}

///|
test "cohen kappa complete disagreement" {
  let ds = @core.Dataset::new("test_kappa_dis", @core.TaskType::Classification, ["Positive", "Negative"])
  let s1 = @core.Sample::create_simple("1", "t1", "Positive", annotator="user1")
  let s1_b : @core.Annotation = { annotator_id: "user2", label: Single("Negative"), timestamp: 0L, confidence: None }
  s1.annotations.push(s1_b)

  let s2 = @core.Sample::create_simple("2", "t2", "Negative", annotator="user1")
  let s2_b : @core.Annotation = { annotator_id: "user2", label: Single("Positive"), timestamp: 0L, confidence: None }
  s2.annotations.push(s2_b)

  ds.add_sample(s1)
  ds.add_sample(s2)

  let kappa = compute_cohen_kappa(ds, "user1", "user2")
  inspect(kappa.kappa_score < 0.0, content="true")
}

///|
test "fleiss kappa multi-annotator" {
  let ds = @core.Dataset::new("test_fleiss", @core.TaskType::Classification, ["A", "B", "C"])
  let s1 = @core.Sample::create_simple("1", "t1", "A", annotator="ann1")
  s1.annotations.push({ annotator_id: "ann2", label: Single("A"), timestamp: 0L, confidence: None })
  s1.annotations.push({ annotator_id: "ann3", label: Single("A"), timestamp: 0L, confidence: None })
  ds.add_sample(s1)

  let fleiss = compute_fleiss_kappa(ds)
  inspect(fleiss.sample_count, content="1")
  inspect(fleiss.kappa_score > 0.999, content="true")
}
