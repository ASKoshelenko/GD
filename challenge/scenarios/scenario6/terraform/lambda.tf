data "archive_file" "sc6-lambda-function" {
  type = "zip"
  source_file = "../assets/lambda.py"
  output_path = "../assets/lambda.zip"
}
resource "aws_iam_role" "sc6-lambda-role" {
  name = "sc6-lambda-role-service-role"
  path  = "/${var.scenario-name}/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "sc6-lambda-role"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_lambda_function" "sc6-lambda-function" {
  filename = "../assets/lambda.zip"
  function_name = "sc6-lambda"
  role = aws_iam_role.sc6-lambda-role.arn
  handler = "lambda.handler"
  source_code_hash = data.archive_file.sc6-lambda-function.output_base64sha256
  runtime = "python3.8"
  environment {
      variables = {
          DB_NAME = var.rds-database-name
          DB_USER = var.rds-username
          DB_PASSWORD = var.rds-password
      }
  }
  tags = {
    Name = "sc6-lambda"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}