# Sc8FinCheck policy
resource "aws_iam_role_policy" "Sc8FinCheck" {
  name = "Sc8FinCheck"
  role = aws_iam_role.Sc8FinCheck.id
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
# Sc8FinCheck role
resource "aws_iam_role" "Sc8FinCheck" {
  name = "Sc8FinCheck"
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

resource "aws_lambda_function" "Sc8FinCheck" {
  filename         = "../lambda/Sc8FinCheck.zip"
  function_name    = "Sc8FinCheck"
  role             = aws_iam_role.Sc8FinCheck.arn
  handler          = "Sc8FinCheck.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc8FinCheck.zip")
  runtime = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_cloudwatch_event_rule" "Sc8FinCheck" {
  name        = "Sc8FinCheck"
  schedule_expression = "rate(10 minutes)" 
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Sc8FinCheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Sc8FinCheck.arn
}

resource "aws_cloudwatch_event_target" "Sc8FinCheck" {
    rule = aws_cloudwatch_event_rule.Sc8FinCheck.name
    target_id = "Sc8FinCheck"
    arn = aws_lambda_function.Sc8FinCheck.arn
}
