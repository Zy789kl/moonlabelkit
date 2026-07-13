///|
/// 数据治理统一错误类型定义
pub(all) suberror GovernanceError {
  SchemaMismatch(String)
  InvalidAnnotation(String)
  ParserError(String, Int)
  ComputationError(String)
} derive(Eq, Debug)

///|
pub impl Show for GovernanceError with fn output(self, logger) {
  match self {
    SchemaMismatch(msg) => logger.write_string("SchemaMismatch: " + msg)
    InvalidAnnotation(msg) => logger.write_string("InvalidAnnotation: " + msg)
    ParserError(msg, line) =>
      logger.write_string(
        "ParserError: " + msg + " (Line " + line.to_string() + ")",
      )
    ComputationError(msg) => logger.write_string("ComputationError: " + msg)
  }
}

///|
/// 抛出Schema校验不通过异常
pub fn raise_schema_error(msg : String) -> Unit raise GovernanceError {
  raise GovernanceError::SchemaMismatch(msg)
}

///|
/// 抛出解析异常与具体行号
pub fn raise_parser_error(
  msg : String,
  line : Int,
) -> Unit raise GovernanceError {
  raise GovernanceError::ParserError(msg, line)
}
