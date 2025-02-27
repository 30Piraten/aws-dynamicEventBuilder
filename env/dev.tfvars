stage = "dev"
resources = {
  ec2 = {
    instance_type = "t2.micro"
    count = 2
  }
  s3 = {
    bucket_name = "dev-bucket"
  }
  rds = {
    engine         = "postgres"
    instance_class = "db.t2.micro"
  }
  vpc = {
    cidr_block = "10.0.0.0/16"
  }
}
ttl = "2024-01-01T00:00:00Z"
