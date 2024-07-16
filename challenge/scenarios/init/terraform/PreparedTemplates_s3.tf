#Bucket creation
resource "aws_s3_bucket" "prepared-user-templates-hackathon" {
  bucket             = "prepared-user-templates-hackathon"
  force_destroy      = true
}
resource "aws_s3_bucket_versioning" "prepared-user-templates-hackathon" {
  bucket = aws_s3_bucket.prepared-user-templates-hackathon.id
  versioning_configuration {
    status           = "Enabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "prepared-user-templates-hackathon" {
  bucket = aws_s3_bucket.prepared-user-templates-hackathon.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [
    aws_s3_bucket.prepared-user-templates-hackathon
  ]
}
resource "aws_s3_bucket_server_side_encryption_configuration" "prepared-user-templates-hackathon" {
  bucket            = aws_s3_bucket.prepared-user-templates-hackathon.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
#Upload to s3
resource "aws_s3_object" "distination" {
  for_each = fileset("../templates/", "*")
  bucket   = aws_s3_bucket.prepared-user-templates-hackathon.id
  key      = each.value
  source   = "../templates/${each.value}"
  depends_on = [
    aws_s3_bucket_ownership_controls.prepared-user-templates-hackathon
  ]
}
