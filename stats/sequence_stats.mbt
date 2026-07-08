///|
/// 序列标注指标统计信息
pub(all) struct SequenceStats {
  total_spans : Int
  spans_per_sample_avg : Double
  avg_span_length : Double
  max_span_length : Int
  label_span_counts : Map[String, Int]
} derive(Eq, Debug)

///|
/// 计算序列标注数据集的片段分布与实体长度特征
pub fn compute_sequence_stats(dataset : @core.Dataset) -> SequenceStats {
  let mut total_spans = 0
  let mut total_length = 0
  let mut max_len = 0
  let counts : Map[String, Int] = {}

  for sample in dataset.samples {
    for ann in sample.annotations {
      match ann.label {
        Spans(spans) =>
          for span in spans {
            total_spans += 1
            let len = span.end - span.start
            if len > 0 {
              total_length += len
              if len > max_len {
                max_len = len
              }
            }
            let cur = match counts.get(span.label) {
              Some(c) => c
              None => 0
            }
            counts[span.label] = cur + 1
          }
        _ => ()
      }
    }
  }

  let sample_cnt = dataset.samples.length()
  let avg_per_sample = if sample_cnt > 0 {
    total_spans.to_double() / sample_cnt.to_double()
  } else {
    0.0
  }
  let avg_len = if total_spans > 0 {
    total_length.to_double() / total_spans.to_double()
  } else {
    0.0
  }

  {
    total_spans,
    spans_per_sample_avg: avg_per_sample,
    avg_span_length: avg_len,
    max_span_length: max_len,
    label_span_counts: counts,
  }
}
