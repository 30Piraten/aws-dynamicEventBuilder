resource "aws_ssm_parameter" "dynamodb_table_name" {
  name = "/project-r3/${var.environment}/dynamodb/${var.table-type}-table-name"
  type = "String"
  #   value = aws_dynamodb_table.env_tracker_dynamo_db.name
  value = var.dynamodb_table_name
}