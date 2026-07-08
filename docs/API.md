# 📚 MoonLabelKit API Reference Guide

This document provides detailed API definitions, type signatures, and usage patterns for the core and parser modules of **MoonLabelKit**.

---

## 1. Core Domain Models (`@core`)

### `pub(all) enum TaskType`
Defines the AI data task paradigm supported by the dataset:
```mbt
pub(all) enum TaskType {
  Classification    // Text classification, sentiment analysis, topic tagging
  SequenceLabeling  // Named Entity Recognition (NER), POS tagging, span extraction
  Tabular           // Structured tabular data with categorical/numerical columns
  PromptResponse    // LLM instruction tuning, SFT, DPO/RLHF alignment datasets
}
```

### `pub(all) enum LabelValue`
Unified representation capable of capturing any label type:
```mbt
pub(all) enum LabelValue {
  Single(String)               // Single category string e.g. "Positive"
  Multi(Array[String])         // Multi-label tags e.g. ["Tech", "Mobile"]
  Spans(Array[EntitySpan])     // Sequence labeling entity spans
  Scores(Map[String, Double])  // Continuous confidence or probability distribution
}
```

### `pub(all) struct Dataset`
The primary data structure holding all sample records:
```mbt
pub(all) struct Dataset {
  name : String
  task_type : TaskType
  samples : Array[Sample]
  schema_labels : Array[String]
}
```
#### Key Methods:
- `Dataset::new(name : String, task_type : TaskType, schema_labels : Array[String]) -> Dataset`: Creates an empty dataset entity.
- `Dataset::add_sample(self : Dataset, sample : Sample) -> Unit`: Appends a single sample to the dataset.
- `Dataset::add_sample_or_merge(self : Dataset, sample : Sample) -> Unit`: Appends or merges annotations if `sample.id` already exists. Essential for multi-annotator workflows where each annotator submits records independently.
- `Dataset::filter_by_split(self : Dataset, target_split : String) -> Dataset`: Returns a subset containing only samples matching the given split (`"train"`, `"dev"`, `"test"`).
- `Dataset::get_all_annotators(self : Dataset) -> Array[String]`: Extracts unique IDs of all contributing annotators.

---

## 2. Parser Engine (`@parser`)

### `pub fn parse_jsonl_dataset(...) -> @core.Dataset raise @core.GovernanceError`
Parses raw JSON Lines (JSONL) text into a structured `@core.Dataset`.
```mbt
pub fn parse_jsonl_dataset(
  raw_content : String,
  dataset_name : String,
  task_type : @core.TaskType,
  schema_labels : Array[String]
) -> @core.Dataset raise @core.GovernanceError
```
- **Error Handling**: Raises `@core.GovernanceError::ParserError(msg, line_no)` if JSON syntax or mandatory fields (`id`, `text`, `label`) are invalid.
- **Auto-Merging**: Automatically calls `add_sample_or_merge` to group annotations from different annotators under the same sample ID.

### `pub fn parse_tabular_dataset(...) -> @core.Dataset raise @core.GovernanceError`
Parses CSV or TSV tabular strings with customized column header mapping:
```mbt
pub fn parse_tabular_dataset(
  raw_content : String,
  dataset_name : String,
  delimiter~ : Char = ',',
  id_col~ : String = "id",
  text_col~ : String = "text",
  label_col~ : String = "label",
  annotator_col~ : String = "annotator",
  split_col~ : String = "split",
  schema_labels~ : Array[String] = []
) -> @core.Dataset raise @core.GovernanceError
```
