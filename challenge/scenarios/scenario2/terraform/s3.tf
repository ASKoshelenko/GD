#Secret S3 Bucket
resource "aws_s3_bucket" "cardholder-data-bucket" {
  bucket = "sc2-government-data"
  force_destroy = true
  tags = {
      Description = "S3 Bucket used for storing sensitive cardholder data."
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}
resource "aws_s3_bucket_versioning" "cardholder-data-bucket" {
  bucket = aws_s3_bucket.cardholder-data-bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cardholder-data-bucket" {
  bucket = aws_s3_bucket.cardholder-data-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
resource "aws_s3_object" "cardholder-data-primary" {
  bucket = aws_s3_bucket.cardholder-data-bucket.id
  key = "cardholder_data_primary.csv"
  source = "../assets/cardholder_data_primary.csv"
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_s3_object" "cardholder-data-secondary" {
  bucket = aws_s3_bucket.cardholder-data-bucket.id
  key = "cardholder_data_secondary.csv"
  source = "../assets/cardholder_data_secondary.csv"
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_s3_object" "cardholder-data-corporate" {
  bucket = aws_s3_bucket.cardholder-data-bucket.id
  key = "cardholders_corporate.csv"
  source = "../assets/cardholders_corporate.csv"
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
