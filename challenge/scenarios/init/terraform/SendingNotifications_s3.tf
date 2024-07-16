#Bucket creation
resource "aws_s3_bucket" "templates-hackaton-notify" {
  bucket = "templates-hackaton-notify"
}
resource "aws_s3_bucket_versioning" "templates-hackaton-notify" {
  bucket = aws_s3_bucket.templates-hackaton-notify.id
  versioning_configuration {
    status = "Disabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "templates-hackaton-notify" {
  bucket = aws_s3_bucket.templates-hackaton-notify.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [
    aws_s3_bucket.templates-hackaton-notify
  ]
}
resource "aws_s3_bucket_server_side_encryption_configuration" "templates-hackaton-notify" {
  bucket = aws_s3_bucket.templates-hackaton-notify.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
#Upload to s3
resource "aws_s3_object" "dist" {
  for_each = fileset("../templates/", "*")
  bucket = aws_s3_bucket.templates-hackaton-notify.id
  key    = each.value
  source = "../templates/${each.value}"
  depends_on = [
    aws_s3_bucket_ownership_controls.templates-hackaton-notify
  ]
}
