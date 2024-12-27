stage = "prod"
resources = {
  ec2 = {
    instance_type = "m5.large"
    count = 3
  }
  s3 = {
    bucket_name = "prod-bucket"
  }
  rds = {
    engine         = "aurora"
    instance_class = "db.r5.large"
  }
  vpc = {
    cidr_block = "10.2.0.0/16"
  }
}
ttl = "2024-01-03T00:00:00Z"
