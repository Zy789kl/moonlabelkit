///|
test "label distribution calculation and entropy" {
  let ds = @core.Dataset::new("test_dist", @core.TaskType::Classification, ["A", "B"])
  let s1 = @core.Sample::create_simple("1", "t1", "A")
  let s2 = @core.Sample::create_simple("2", "t2", "A")
  let s3 = @core.Sample::create_simple("3", "t3", "B")
  let s4 = @core.Sample::create_simple("4", "t4", "B")
  ds.add_sample(s1)
  ds.add_sample(s2)
  ds.add_sample(s3)
  ds.add_sample(s4)

  let dist = compute_label_distribution(ds)
  inspect(dist.total_annotations, content="4")
  inspect(dist.max_min_ratio, content="1")
  // 当两种标签 50/50 分布时，二元信息熵正好等于 1.0 bit
  inspect(dist.shannon_entropy > 0.99 && dist.shannon_entropy < 1.01, content="true")
  inspect(is_severely_imbalanced(dist, threshold=5.0), content="false")
}

///|
test "sequence stats calculation" {
  let ds = @core.Dataset::new("test_seq", @core.TaskType::SequenceLabeling, ["ORG", "LOC"])
  let span1 : @core.EntitySpan = { start: 0, end: 10, label: "ORG", text: "MoonBit Co" }
  let span2 : @core.EntitySpan = { start: 15, end: 22, label: "LOC", text: "Beijing" }
  let sample = @core.Sample::create_sequence("seq_1", "MoonBit Co is in Beijing.", [span1, span2])
  ds.add_sample(sample)

  let stats = compute_sequence_stats(ds)
  inspect(stats.total_spans, content="2")
  inspect(stats.spans_per_sample_avg, content="2")
  inspect(stats.max_span_length, content="10")
}
