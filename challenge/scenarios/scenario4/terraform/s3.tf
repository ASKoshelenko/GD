#Secret S3 Bucket
resource "aws_s3_bucket" "sc4-secret-s3-bucket" {
  bucket = "sc4-secret-s3-bucket"
  force_destroy = true
  tags = {
      Name = "sc4-secret-s3-bucket"
      Description = "SecurityChallenge S3 Bucket used for storing a secret"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}
resource "aws_s3_bucket_versioning" "sc4-secret-s3-bucket" {
  bucket = aws_s3_bucket.sc4-secret-s3-bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sc4-secret-s3-bucket" {
  bucket = aws_s3_bucket.sc4-secret-s3-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_object" "scenario4_3_users-credentials" {
  bucket = aws_s3_bucket.sc4-secret-s3-bucket.id
  key = "admin-user.txt"
  source = "../assets/admin-user.txt"
  depends_on = [
    null_resource.sc4-create-sheperds-credentials-file
  ]
  tags = {
    Name = "scenario4_3_users-credentials"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}