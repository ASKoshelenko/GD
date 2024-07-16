# Sc7FinCheck policy
resource "aws_iam_role_policy" "Sc7FinalCheck" {
  name = "Sc7FinalCheck"
  role = aws_iam_role.Sc7FinalCheck.id
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
# Sc7FinCheck role
resource "aws_iam_role" "Sc7FinalCheck" {
  name = "Sc7FinalCheck"
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

resource "aws_lambda_function" "Sc7FinalCheck" {
  filename         = "../lambda/Sc7FinalCheck.zip"
  function_name    = "Sc7FinalCheck"
  role             = aws_iam_role.Sc7FinalCheck.arn
  handler          = "Sc7FinalCheck.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc7FinalCheck.zip")
  runtime = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_cloudwatch_event_rule" "Sc7FinalCheck" {
  name        = "Sc7FinalCheck"
  schedule_expression = "rate(15 minutes)" 
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Sc7FinalCheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Sc7FinalCheck.arn
}

resource "aws_cloudwatch_event_target" "Sc7FinalCheck" {
    rule = aws_cloudwatch_event_rule.Sc7FinalCheck.name
    target_id = "Sc7FinalCheck"
    arn = aws_lambda_function.Sc7FinalCheck.arn
}
