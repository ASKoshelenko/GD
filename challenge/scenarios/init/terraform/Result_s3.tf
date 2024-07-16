resource "aws_s3_bucket" "result_bucket" {
  bucket             = var.result_bucket_name
  force_destroy      = true
}
resource "aws_s3_bucket_versioning" "result_bucket" {
  bucket = aws_s3_bucket.result_bucket.id
  versioning_configuration {
    status           = "Disabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "result_bucket" {
  bucket = aws_s3_bucket.result_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [
    aws_s3_bucket.result_bucket
  ]
}
resource "aws_s3_bucket_server_side_encryption_configuration" "result_bucket" {
  bucket            = aws_s3_bucket.result_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
