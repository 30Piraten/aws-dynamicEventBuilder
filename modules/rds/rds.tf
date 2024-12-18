locals {
  ttl_expiry = 3
}

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

  username = "r3ev"
  password = "root9090909"

  tags = {
    TTL = timeadd(timestamp(), "${local.ttl_expiry}m")
  }
}