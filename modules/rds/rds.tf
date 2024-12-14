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
  db_subnet_group_name = aws_db_subnet_group.db_subnet.id

#   username = ""
#   password = ""
}

resource "aws_db_subnet_group" "db_subnet" {
  name = var.db_subnet_name
  subnet_ids = [ aws_subnet.public.id, aws_subnet.private.id ]

  tags = var.db_subnet_tags
}