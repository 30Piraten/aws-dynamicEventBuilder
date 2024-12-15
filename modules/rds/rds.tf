resource "aws_db_instance" "db_sql" {

  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  allocated_storage    = var.allocated_storage
  instance_class       = var.instance_class
  parameter_group_name = var.parameter_group_name
  skip_final_snapshot  = var.skip_final_snapshot
  multi_az             = var.multi_az
  publicly_accessible  = var.publicly_accessible
  # db_subnet_group_name = module.db_subnet_group_name #

  #   username = ""
  #   password = ""
}