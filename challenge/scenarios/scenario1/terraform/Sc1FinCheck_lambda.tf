# Sc1FinCheck policy
resource "aws_iam_role_policy" "Sc1FinCheck" {
  name = "Sc1FinCheck"
  role = aws_iam_role.Sc1FinCheck.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
		    {
          "Sid": "Terraform1",
          "Action": [
            "cloudtrail:LookupEvents",
            "dynamodb:Scan",
            "dynamodb:UpdateItem",
            "dynamodb:GetItem",
            "lambda:InvokeFunction",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
    ]
}
EOF
}
# Sc1FinCheck role
resource "aws_iam_role" "Sc1FinCheck" {
  name = "Sc1FinCheck"
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
}

resource "aws_lambda_function" "Sc1FinCheck" {
  filename         = "../lambda/Sc1FinCheck.zip"
  function_name    = "Sc1FinCheck"
  role             = aws_iam_role.Sc1FinCheck.arn
  handler          = "Sc1FinCheck.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc1FinCheck.zip")
  runtime = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_cloudwatch_event_rule" "Sc1FinCheck" {
  name        = "Sc1FinCheck"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Sc1FinCheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Sc1FinCheck.arn
}

resource "aws_cloudwatch_event_target" "Sc1FinCheck" {
    rule = aws_cloudwatch_event_rule.Sc1FinCheck.name
    target_id = "Sc1FinCheck"
    arn = aws_lambda_function.Sc1FinCheck.arn
}
