stage = "test"
resources = {
  ec2 = {
    instance_type = "t3.medium"
    count = 1
  }
  s3 = {
    bucket_name = "test-bucket"
  }
  rds = {
    engine         = "mysql"
    instance_class = "db.t3.medium"
  }
  vpc = {
    cidr_block = "10.1.0.0/16"
  }
}
ttl = "2024-01-02T00:00:00Z"
