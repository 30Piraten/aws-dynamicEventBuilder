resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket

  tags = var.bucket_tags
}