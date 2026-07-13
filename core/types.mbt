///|
/// 任务类型枚举，支持分类、序列标注与表格化/大模型评测数据
pub(all) enum TaskType {
  Classification
  SequenceLabeling
  Tabular
  PromptResponse
} derive(Eq, Debug, ToJson)

///|
/// 序列标注中的实体片段定义
pub(all) struct EntitySpan {
  start : Int
  end : Int
  label : String
  text : String
} derive(Eq, Debug, ToJson)

///|
/// 统一标签值表达，涵盖单类别、多类别、序列标注区间与置信评分
pub(all) enum LabelValue {
  Single(String)
  Multi(Array[String])
  Spans(Array[EntitySpan])
  Scores(Map[String, Double])
} derive(Eq, Debug)

///|
/// 单次标注记录，关联标注人员ID、标签结果、时间戳及可选置信度
pub(all) struct Annotation {
  annotator_id : String
  label : LabelValue
  timestamp : Int64
  confidence : Double?
} derive(Eq, Debug)

///|
/// 数据集单条样本模型
pub(all) struct Sample {
  id : String
  text : String
  metadata : Map[String, String]
  annotations : Array[Annotation]
  split : String
} derive(Eq, Debug)

///|
/// 数据集实体定义
pub(all) struct Dataset {
  name : String
  task_type : TaskType
  samples : Array[Sample]
  schema_labels : Array[String]
} derive(Eq, Debug)

///|
/// 创建全新空数据集实体
pub fn Dataset::new(
  name : String,
  task_type : TaskType,
  schema_labels : Array[String],
) -> Dataset {
  { name, task_type, samples: [], schema_labels }
}

///|
/// 往数据集中追加单条样本
pub fn Dataset::add_sample(self : Dataset, sample : Sample) -> Unit {
  self.samples.push(sample)
}

///|
/// 往数据集中添加样本，如果ID已存在则合并标注记录（适用于多标注人员独立提交的记录）
pub fn Dataset::add_sample_or_merge(self : Dataset, sample : Sample) -> Unit {
  for existing in self.samples {
    if existing.id == sample.id {
      for ann in sample.annotations {
        existing.annotations.push(ann)
      }
      return
    }
  }
  self.samples.push(sample)
}

///|
/// 构造基础单标注样本
pub fn Sample::create_simple(
  id : String,
  text : String,
  label : String,
  annotator? : String = "default",
  split? : String = "train",
) -> Sample {
  let ann : Annotation = {
    annotator_id: annotator,
    label: LabelValue::Single(label),
    timestamp: 0L,
    confidence: None,
  }
  { id, text, metadata: {}, annotations: [ann], split }
}

///|
/// 构造基础序列标注样本
pub fn Sample::create_sequence(
  id : String,
  text : String,
  spans : Array[EntitySpan],
  annotator? : String = "default",
  split? : String = "train",
) -> Sample {
  let ann : Annotation = {
    annotator_id: annotator,
    label: LabelValue::Spans(spans),
    timestamp: 0L,
    confidence: None,
  }
  { id, text, metadata: {}, annotations: [ann], split }
}

///|
/// 提取单条样本下的所有分类类别字符串（对单标签/多标签展开去重）
pub fn Sample::extract_category_labels(self : Sample) -> Array[String] {
  let res = {}
  let out = []
  for ann in self.annotations {
    match ann.label {
      Single(lbl) =>
        if !res.contains(lbl) {
          res[lbl] = true
          out.push(lbl)
        }
      Multi(lbls) =>
        for lbl in lbls {
          if !res.contains(lbl) {
            res[lbl] = true
            out.push(lbl)
          }
        }
      Spans(spans) =>
        for span in spans {
          if !res.contains(span.label) {
            res[span.label] = true
            out.push(span.label)
          }
        }
      Scores(map) =>
        for k, _ in map {
          if !res.contains(k) {
            res[k] = true
            out.push(k)
          }
        }
    }
  }
  out
}

///|
/// 按照数据集切分类型（如 "train", "dev", "test"）过滤返回子数据集
pub fn Dataset::filter_by_split(
  self : Dataset,
  target_split : String,
) -> Dataset {
  let filtered_samples = []
  for s in self.samples {
    if s.split == target_split {
      filtered_samples.push(s)
    }
  }
  {
    name: "\{self.name}_\{target_split}",
    task_type: self.task_type,
    samples: filtered_samples,
    schema_labels: self.schema_labels,
  }
}

///|
/// 获取数据集中出现的所有不同标注人员ID列表
pub fn Dataset::get_all_annotators(self : Dataset) -> Array[String] {
  let seen = {}
  let annotators = []
  for sample in self.samples {
    for ann in sample.annotations {
      if !seen.contains(ann.annotator_id) {
        seen[ann.annotator_id] = true
        annotators.push(ann.annotator_id)
      }
    }
  }
  annotators
}
