resource "aws_iam_role_policy" "Sc3CollectEvents" {
  name = "Sc3CollectEvents"
  role = aws_iam_role.Sc3CollectEvents.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid"   : "Terraform",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
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

resource "aws_iam_role" "Sc3CollectEvents" {
  name = "Sc3CollectEvents"
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

resource "aws_lambda_function" "Sc3CollectEvents" {
  filename         = "../lambda/Sc3CollectEvents.zip"
  function_name    = "Sc3CollectEvents"
  role             = aws_iam_role.Sc3CollectEvents.arn
  handler          = "Sc3CollectEvents.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc3CollectEvents.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_cloudwatch_event_rule" "Sc3CollectEvents" {
  name        = "Sc3CollectEvents"
  schedule_expression = "rate(15 minutes)" 
}

resource "aws_lambda_permission" "Sc3CollectEvents" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Sc3CollectEvents.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Sc3CollectEvents.arn
}

resource "aws_cloudwatch_event_target" "Sc3CollectEvents" {
    rule = aws_cloudwatch_event_rule.Sc3CollectEvents.name
    target_id = "Sc3CollectEvents"
    arn = aws_lambda_function.Sc3CollectEvents.arn
}
