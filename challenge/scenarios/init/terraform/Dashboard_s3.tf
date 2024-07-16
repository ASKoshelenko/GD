resource "aws_s3_bucket" "dashboard" {
  bucket = "gameday-dashboard"
}

resource "aws_s3_bucket_versioning" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id
   versioning_configuration {
    status = "Disabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [
    aws_s3_bucket.dashboard
  ]
}



resource "aws_s3_bucket_server_side_encryption_configuration" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_policy" "dashboard_policy" {
  bucket = aws_s3_bucket.dashboard.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.dashboard.arn}",
        "${aws_s3_bucket.dashboard.arn}/*"
      ]
    }
  ]
}
EOF
  depends_on = [ aws_s3_bucket_public_access_block.dashboard ]
}
variable "upload_directory" {
  default = "../dashboard/"
}

 locals {
  mime_types = {
    htm   = "text/html"
    html  = "text/html"
    css   = "text/css"
    ttf   = "font/ttf"
    eot   = "font/eot"
    svg   = "font/svg"
    js    = "application/javascript"
    map   = "application/javascript"
    json  = "application/json"
  }
}

resource "aws_s3_object" "website_files" {
  for_each      = fileset(var.upload_directory, "**/*.*")
  bucket        = aws_s3_bucket.dashboard.id
  key           = replace(each.value, var.upload_directory, "")
  source        = "${var.upload_directory}${each.value}"
  etag          = filemd5("${var.upload_directory}${each.value}")
  content_type  = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "binary/octet-stream")
  depends_on    = [ aws_s3_bucket_ownership_controls.dashboard ]
}
