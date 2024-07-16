resource "aws_s3_bucket" "sc7-secret-s3-bucket" {
  bucket = "sc7-secret-s3-bucket"
  force_destroy = true
  tags = {
      Name = "sc7-secret-s3-bucket"
      Description = "SecurityChallenge S3 Bucket used for storing a secret"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_versioning" "sc7-secret-s3-bucket" {
  bucket = aws_s3_bucket.sc7-secret-s3-bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sc7-secret-s3-bucket" {
  bucket = aws_s3_bucket.sc7-secret-s3-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
resource "aws_s3_object" "scenario7-final-action" {
  bucket = aws_s3_bucket.sc7-secret-s3-bucket.id
  key = "Sc7-final"
  source = "../Sc7-final"
  tags = {
    Name = "scenario7-final-action"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}