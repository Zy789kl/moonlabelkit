///|
/// Command-line options for the governance report executable.
struct CliOptions {
  mut input : String?
  mut format : String
  mut dataset_name : String
  mut task : @core.TaskType
  mut schema_labels : Array[String]
}

///|
fn split_schema(value : String) -> Array[String] {
  let labels = []
  for item in value.split(",") {
    let label = item.trim().to_owned()
    if label != "" {
      labels.push(label)
    }
  }
  labels
}

///|
fn default_options() -> CliOptions {
  {
    input: None,
    format: "demo",
    dataset_name: "MoonLabelKit_Dataset",
    task: @core.TaskType::Classification,
    schema_labels: [],
  }
}

///|
fn print_help() -> Unit {
  println(
    (
      #|MoonLabelKit data governance CLI
      #|
      #|Usage:
      #|  moon run cmd -- --input FILE [options]
      #|  moon run cmd                         # run the built-in demo
      #|
      #|Options:
      #|  --input FILE       JSONL, CSV or TSV file to inspect
      #|  --format FORMAT    auto, jsonl, csv or tsv (default: auto)
      #|  --name NAME        dataset name shown in the report
      #|  --task TASK        classification or sequence (JSONL only)
      #|  --schema A,B,C     allowed labels used for schema checks
      #|  --help              show this help
    ),
  )
}

///|
fn parse_cli(args : Array[String]) -> CliOptions? {
  let options = default_options()
  let mut index = 1
  while index < args.length() {
    let arg = args[index]
    if arg == "--help" || arg == "-h" {
      print_help()
      return None
    } else if arg == "--input" {
      if index + 1 >= args.length() {
        println("Error: --input requires a file path")
        return None
      }
      options.input = Some(args[index + 1])
      options.format = "auto"
      index += 2
    } else if arg == "--format" {
      if index + 1 >= args.length() {
        println("Error: --format requires auto, jsonl, csv or tsv")
        return None
      }
      options.format = args[index + 1].to_lower()
      index += 2
    } else if arg == "--name" {
      if index + 1 >= args.length() {
        println("Error: --name requires a value")
        return None
      }
      options.dataset_name = args[index + 1]
      index += 2
    } else if arg == "--task" {
      if index + 1 >= args.length() {
        println("Error: --task requires classification or sequence")
        return None
      }
      let task = args[index + 1].to_lower()
      options.task = if task == "sequence" || task == "sequencelabeling" {
        @core.TaskType::SequenceLabeling
      } else {
        @core.TaskType::Classification
      }
      index += 2
    } else if arg == "--schema" {
      if index + 1 >= args.length() {
        println("Error: --schema requires a comma-separated label list")
        return None
      }
      options.schema_labels = split_schema(args[index + 1])
      index += 2
    } else {
      println("Error: unknown argument `{arg}`; use --help for usage")
      return None
    }
  }
  Some(options)
}

///|
fn infer_format(path : String) -> String {
  let lower = path.to_lower()
  if lower.has_suffix(".jsonl") || lower.has_suffix(".json") {
    "jsonl"
  } else if lower.has_suffix(".tsv") {
    "tsv"
  } else {
    "csv"
  }
}

///|
fn resolve_format(options : CliOptions, path : String) -> String {
  if options.format == "auto" {
    infer_format(path)
  } else {
    options.format
  }
}

///|
fn parse_input(
  content : String,
  options : CliOptions,
  format : String,
) -> @core.Dataset raise @core.GovernanceError {
  if format == "jsonl" {
    @parser.parse_jsonl_dataset(
      content,
      options.dataset_name,
      options.task,
      options.schema_labels,
    )
  } else if format == "csv" || format == "tsv" {
    let delimiter = if format == "tsv" { '\t' } else { ',' }
    @parser.parse_tabular_dataset(
      content,
      options.dataset_name,
      options.schema_labels,
      delimiter~,
    )
  } else {
    raise @core.GovernanceError::ParserError(
      "format must be auto, jsonl, csv or tsv", 0,
    )
  }
}
