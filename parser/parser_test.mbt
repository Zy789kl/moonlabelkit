///|
test "parse jsonl classification dataset" {
  let jsonl_data =
    #|{"id": "doc_1", "text": "I love this product", "label": "Positive", "annotator": "alice", "split": "train"}
    #|{"id": "doc_2", "text": "This is terrible and broken", "label": "Negative", "annotator": "bob", "split": "train"}
    #|{"id": "doc_3", "text": "Not sure how to feel about it", "label": "Neutral", "annotator": "alice", "split": "dev"}
  let ds = parse_jsonl_dataset(
    jsonl_data,
    "sentiment_dataset",
    @core.TaskType::Classification,
    ["Positive", "Negative", "Neutral"],
  )
  inspect(ds.samples.length(), content="3")
  inspect(ds.get_all_annotators().length(), content="2")
  let s1_labels = ds.samples[0].extract_category_labels()
  debug_inspect(s1_labels, content="[\"Positive\"]")
}

///|
test "parse jsonl sequence labeling dataset" {
  let jsonl_seq =
    #|{"id": "ner_1", "text": "Google is headquartered in Mountain View.", "spans": [{"start": 0, "end": 6, "label": "ORG", "text": "Google"}, {"start": 27, "end": 40, "label": "LOC", "text": "Mountain View"}], "annotator": "expert"}
  let ds = parse_jsonl_dataset(
    jsonl_seq,
    "ner_dataset",
    @core.TaskType::SequenceLabeling,
    ["ORG", "LOC", "PER"],
  )
  inspect(ds.samples.length(), content="1")
  let s1_labels = ds.samples[0].extract_category_labels()
  debug_inspect(s1_labels, content="[\"ORG\", \"LOC\"]")
}

///|
test "parse sequence dataset using label span array convention" {
  let jsonl_seq =
    #|{"id": "ner_label_1", "text": "OpenAI builds models.", "label": [{"start": 0, "end": 6, "label": "ORG", "text": "OpenAI"}], "annotator": "expert"}
  let ds = parse_jsonl_dataset(
    jsonl_seq,
    "ner_label_dataset",
    @core.TaskType::SequenceLabeling,
    ["ORG"],
  )
  inspect(ds.samples.length(), content="1")
  debug_inspect(ds.samples[0].extract_category_labels(), content="[\"ORG\"]")
}

///|
test "parse csv tabular dataset" {
  let csv_data =
    #|id,text,label,annotator,split
    #|101,"Excellent quality, very easy to use.",Positive,alice,train
    #|102,Bad experience,Negative,bob,test
  let ds = parse_tabular_dataset(
    csv_data,
    "tabular_sentiment",
    ["Positive", "Negative"],
    delimiter=',',
  )
  inspect(ds.samples.length(), content="2")
  let s2_labels = ds.samples[1].extract_category_labels()
  debug_inspect(s2_labels, content="[\"Negative\"]")
  inspect(ds.samples[0].annotations[0].annotator_id, content="alice")
  inspect(ds.samples[1].split, content="test")
}
