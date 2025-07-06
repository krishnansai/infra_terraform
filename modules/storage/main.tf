resource "aws_s3_bucket" "state" {
  bucket = var.bucket_name
  force_destroy = true
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_arn" {
  value = aws_s3_bucket.state.arn
}
