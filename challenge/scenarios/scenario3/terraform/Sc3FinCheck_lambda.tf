resource "aws_iam_role_policy" "Sc3FinCheck" {
  name = "Sc3FinCheck"
  role = aws_iam_role.Sc3FinCheck.id
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
        "lambda:InvokeFunction",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "Sc3FinCheck" {
  name = "Sc3FinCheck"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service":"lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "Sc3FinCheck" {
  filename         = "../lambda/Sc3FinCheck.zip"
  function_name    = "Sc3FinCheck"
  role             = aws_iam_role.Sc3FinCheck.arn
  handler          = "Sc3FinCheck.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc3FinCheck.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_cloudwatch_event_rule" "Sc3FinCheck" {
  name        = "Sc3FinCheck"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "terminated"
    ]
  }
}
PATTERN
}

resource "aws_lambda_permission" "Sc3FinCheck" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Sc3FinCheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Sc3FinCheck.arn
}

resource "aws_cloudwatch_event_target" "Sc3FinCheck" {
    rule = aws_cloudwatch_event_rule.Sc3FinCheck.name
    target_id = "Sc3FinCheck"
    arn = aws_lambda_function.Sc3FinCheck.arn
}
