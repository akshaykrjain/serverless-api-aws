resource "aws_s3_bucket" "data" {
  acl = "private"
  tags = {
    Name        = "Data Bucket for API"
    Environment = "Prod"
  }
}