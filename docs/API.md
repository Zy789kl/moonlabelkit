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
- **Error Handling**: Raises `@core.GovernanceError::ParserError(msg, line_no)` if JSON syntax or mandatory fields (`text`, and `label`/`labels` for classification) are invalid. Missing `id`, `annotator`, and `split` values receive deterministic defaults.
- **Auto-Merging**: Automatically calls `add_sample_or_merge` to group annotations from different annotators under the same sample ID.

### `pub fn parse_tabular_dataset(...) -> @core.Dataset raise @core.GovernanceError`
Parses CSV or TSV tabular strings with customized column header mapping:
```mbt
pub fn parse_tabular_dataset(
  content : String,
  dataset_name : String,
  schema_labels : Array[String],
  delimiter? : Char = ','
) -> @core.Dataset raise @core.GovernanceError
```

The parser recognizes `id`, `text`/`content`/`sentence`,
`label`/`category`/`target`, `annotator`/`annotator_id`, and `split` headers.
The `id` column is optional (a line-number ID is generated when absent), and
missing annotator/split columns use `default` and `train` respectively. CSV
fields may be quoted and may contain the delimiter.

### Command-line input

The executable accepts real files and keeps the library parser API separate
from filesystem concerns:

```bash
moon run cmd -- --input examples/sentiment_reviews.jsonl \
  --format jsonl --schema Positive,Negative,Neutral
moon run cmd -- --input examples/sentiment_reviews.csv \
  --format csv --schema Positive,Negative,Neutral
moon run cmd -- --input examples/ner_entities.jsonl \
  --format jsonl --task sequence --schema ORG,PROD,LOC,PER
```

Use `--format auto` (the default for `--input`) to infer JSONL, CSV, or TSV
from the file suffix. `moon run cmd` without `--input` continues to run the
deterministic built-in demonstration dataset.

## 3. Statistics (`@stats`)

`compute_label_distribution(dataset)` returns `LabelDistribution`, including
`shannon_entropy`, `gini_imbalance`, and `max_min_ratio`. Despite the field's
backwards-compatible name, `gini_imbalance` is the pairwise Gini inequality
coefficient defined in `docs/THEORY.md`, not Gini impurity.

For sequence JSONL, the parser accepts either `spans: [{...}]` or the common
`label: [{...}]` span-array convention used by the bundled NER fixture.
