# Policy for finalizing lambda of scenario5
resource "aws_iam_role_policy" "sc5_logs_getting" {
  name = "sc5_logs_getting"
  role = aws_iam_role.sc5_logs_getting.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudtrail:LookupEvents",
                "dynamodb:Scan",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "sc5_logs_getting" {
  name = "sc5_logs_getting"
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

resource "aws_lambda_function" "sc5_logs_getting" {
  filename         = "../lambda/sc5_logs_getting.zip"
  function_name    = "sc5_logs_getting"
  role             = aws_iam_role.sc5_logs_getting.arn
  handler          = "sc5_logs_getting.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/sc5_logs_getting.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_cloudwatch_event_rule" "sc5_logs_getting" {
  name        = "sc5_logs_getting"
  schedule_expression = "rate(15 minutes)" 
}

resource "aws_lambda_permission" "sc5_logs_getting" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sc5_logs_getting.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sc5_logs_getting.arn
}

resource "aws_cloudwatch_event_target" "sc5_logs_getting" {
    rule = aws_cloudwatch_event_rule.sc5_logs_getting.name
    target_id = "sc5_logs_getting"
    arn = aws_lambda_function.sc5_logs_getting.arn
}