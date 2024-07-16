#Logs S3 Bucket Policy
resource "aws_s3_bucket_policy" "sc5-logs-s3-bucket-policy" {
  bucket = aws_s3_bucket.sc5-logs-s3-bucket.id
  policy = <<POLICY
{
  "Id": "Policy1558803362844",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1558803360562",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.sc5-logs-s3-bucket.arn}/sc5-lb-logs/AWSLogs/${data.aws_caller_identity.aws-account-id.account_id}/*",
      "Principal": {
        "AWS": [
          "054676820928"
        ]
      }
    }
  ]
}
POLICY
}
#Logs S3 Bucket
resource "aws_s3_bucket" "sc5-logs-s3-bucket" {
  bucket = "sc5-logs-s3-bucket"
  force_destroy = true
  tags = {
      Description = "${var.scenario-name} S3 Bucket used for ALB Logs"
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}
resource "aws_s3_bucket_versioning" "sc5-logs-s3-bucket" {
  bucket = aws_s3_bucket.sc5-logs-s3-bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sc5-logs-s3-bucket" {
  bucket = aws_s3_bucket.sc5-logs-s3-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
#Secret S3 Bucket
resource "aws_s3_bucket" "sc5-secret-s3-bucket" {
  bucket = "sc5-secret-s3-bucket"
  force_destroy = true
  tags = {
      Description = "${var.scenario-name} S3 Bucket used for storing a secret"
      Stack = var.stack-name
      Scenario = var.scenario-name
  }
}
resource "aws_s3_bucket_versioning" "sc5-secret-s3-bucket" {
  bucket = aws_s3_bucket.sc5-secret-s3-bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sc5-secret-s3-bucket" {
  bucket = aws_s3_bucket.sc5-secret-s3-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
#Keystore S3 Bucket
resource "aws_s3_bucket" "sc5-keystore-s3-bucket" {
  bucket = "sc5-keystore-s3-bucket"
  force_destroy = true
  tags = {
    Description = "${var.scenario-name} S3 Bucket used for storing ssh keys"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_s3_bucket_versioning" "sc5-keystore-s3-bucket" {
  bucket = aws_s3_bucket.sc5-keystore-s3-bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sc5-keystore-s3-bucket" {
  bucket = aws_s3_bucket.sc5-keystore-s3-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
#S3 Bucket Objects
resource "aws_s3_object" "sc5-lb-log-file" {
  bucket = aws_s3_bucket.sc5-logs-s3-bucket.id
  key = "sc5-lb-logs/AWSLogs/${data.aws_caller_identity.aws-account-id.account_id}/elasticloadbalancing/${var.region}/2019/06/19/555555555555_elasticloadbalancing_eu-central-1_app.sc5-lb.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log"
  source = "../assets/555555555555_elasticloadbalancing_eu-central-1_app.sc5-lb.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log"
  tags = {
    Name = "sc5-lb-log-file"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_s3_object" "sc5-db-credentials-file" {
  bucket = aws_s3_bucket.sc5-secret-s3-bucket.id
  key = "db.txt"
  source = "../assets/db.txt"
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_s3_object" "sc5-ssh-private-key-file" {
  bucket = aws_s3_bucket.sc5-keystore-s3-bucket.id
  key = "SecurityChallenge"
  source = var.ssh-private-key-for-ec2
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_s3_object" "sc5-ssh-public-key-file" {
  bucket = aws_s3_bucket.sc5-keystore-s3-bucket.id
  key = "SecurityChallenge.pub"
  source = var.ssh-public-key-for-ec2
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}