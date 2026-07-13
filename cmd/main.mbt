///|
/// MoonLabelKit 主程序入口：执行多模态标注数据治理巡检流程并输出报告
fn main {
  println("==========================================================")
  println(" 🌌 MoonLabelKit v0.1.0 - Annotation Data Governance Engine ")
  println("==========================================================\n")

  // 1. 使用 Parser 从 JSONL 文本构建一个真实场景的多标注情感分类数据集
  let jsonl_sample =
    #|{"id": "rev_001", "text": "This phone camera is absolutely stunning and super fast!", "label": "Positive", "annotator": "Alice", "split": "train"}
    #|{"id": "rev_001", "text": "This phone camera is absolutely stunning and super fast!", "label": "Positive", "annotator": "Bob", "split": "train"}
    #|{"id": "rev_001", "text": "This phone camera is absolutely stunning and super fast!", "label": "Neutral", "annotator": "Charlie", "split": "train"}
    #|{"id": "rev_002", "text": "Battery drains in just 3 hours. Terrible quality control.", "label": "Negative", "annotator": "Alice", "split": "train"}
    #|{"id": "rev_002", "text": "Battery drains in just 3 hours. Terrible quality control.", "label": "Negative", "annotator": "Bob", "split": "train"}
    #|{"id": "rev_003", "text": "OK phone for the price, decent screen.", "label": "Neutral", "annotator": "Alice", "split": "dev"}
    #|{"id": "rev_004", "text": "x", "label": "Positive", "annotator": "Alice", "split": "test"}
    #|{"id": "rev_005", "text": "Invalid product tag here.", "label": "SuperGood", "annotator": "Bob", "split": "train"}
    #|{"id": "rev_006_dup", "text": "OK phone for the price, decent screen.", "label": "Positive", "annotator": "Charlie", "split": "train"}

  let dataset = @parser.parse_jsonl_dataset(
    jsonl_sample,
    "Mobile_Phone_Reviews_MultiAnn_v1",
    @core.TaskType::Classification,
    ["Positive", "Negative", "Neutral"],
  ) catch {
    err => {
      println("Error parsing dataset: \{err}")
      return
    }
  }

  // 2. 生成综合数据治理报告
  let report = generate_governance_report(dataset)
  println(report)
}
