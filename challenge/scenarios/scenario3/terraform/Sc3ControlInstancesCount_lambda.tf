resource "aws_iam_role_policy" "Sc3ControlInstancesCount" {
  name = "Sc3ControlInstancesCount"
  role = aws_iam_role.Sc3ControlInstancesCount.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Terraform",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "cloudtrail:LookupEvents",
        "sns:Publish",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem",
        "ec2:DescribeInstances",
        "ec2:TerminateInstances",
        "iam:CreatePolicy",
        "iam:GetPolicyVersion",
        "iam:GetPolicy",
        "iam:ListPolicyVersions",
        "iam:AttachUserPolicy",
        "iam:DeletePolicy",
        "iam:DetachUserPolicy",
        "iam:DeletePolicyVersion"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "Sc3ControlInstancesCount" {
  name = "Sc3ControlInstancesCount"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Terraform",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"      
    }
  ]
}
EOF
}

resource "aws_lambda_function" "Sc3ControlInstancesCount" {
  filename         = "../lambda/Sc3ControlInstancesCount.zip"
  function_name    = "Sc3ControlInstancesCount"
  role             = aws_iam_role.Sc3ControlInstancesCount.arn
  handler          = "Sc3ControlInstancesCount.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc3ControlInstancesCount.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_cloudwatch_event_rule" "Sc3ControlInstancesCount" {
  name        = "Sc3ControlInstancesCount"
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
      "pending"
    ]
  }
}
PATTERN
}

resource "aws_lambda_permission" "Sc3ControlInstancesCount" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Sc3ControlInstancesCount.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Sc3ControlInstancesCount.arn
}

resource "aws_cloudwatch_event_target" "Sc3ControlInstancesCount" {
    rule = aws_cloudwatch_event_rule.Sc3ControlInstancesCount.name
    target_id = "Sc3ControlInstancesCount"
    arn = aws_lambda_function.Sc3ControlInstancesCount.arn
}
