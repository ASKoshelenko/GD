# Create lambda_function
resource "aws_lambda_function" "RefreshDashboard" {
  filename         = "../lambda/RefreshDashboard.zip"
  function_name    = "RefreshDashboard"
  role             = aws_iam_role.RefreshDashboard.arn
  handler          = "RefreshDashboard.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/RefreshDashboard.zip")
  runtime          = "python3.8"
  memory_size      = 256
  timeout          = 300
  environment {
    variables = {
      bucketName = "gameday-dashboard"
    }
  }
}

resource "aws_iam_role" "RefreshDashboard" {
  name = "RefreshDashboard"

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
# Create Inline IAM policy for Cloud Watch
resource "aws_iam_policy" "RefreshDashboard_AWSCloudWatchlogs" {
  name   = "RefreshDashboard_AWSCloudWatchlogs"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}
# Block policy_attachment
resource "aws_iam_role_policy_attachment" "RefreshDashboard" {
  role       = aws_iam_role.RefreshDashboard.name
  policy_arn = aws_iam_policy.RefreshDashboard_AWSCloudWatchlogs.arn
}

resource "aws_iam_role_policy_attachment" "RefreshDashboard2" {
  role       = aws_iam_role.RefreshDashboard.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "RefreshDashboard3" {
  role       = aws_iam_role.RefreshDashboard.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}


resource "aws_iam_role_policy_attachment" "RefreshDashboard4" {
  role       = aws_iam_role.RefreshDashboard.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_event_rule" "RefreshDashboard" {
  name        = "RefreshDashboard"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_lambda_permission" "allow_run_RefreshDashboard" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.RefreshDashboard.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.RefreshDashboard.arn
}

resource "aws_cloudwatch_event_target" "RefreshDashboard" {
    rule = aws_cloudwatch_event_rule.RefreshDashboard.name
    target_id = "RefreshDashboard"
    arn = aws_lambda_function.RefreshDashboard.arn
}

