# Create IAM role
resource "aws_iam_role" "SNSAccessForLamdaRole" {
  name = "SNSAccessForLamdaRole"

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
resource "aws_iam_policy" "InitializeUsers_AWSCloudWatchlogs" {
  name   = "InitializeUsers_AWSCloudWatchlogs"
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
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.SNSAccessForLamdaRole.name
  policy_arn = aws_iam_policy.InitializeUsers_AWSCloudWatchlogs.arn
}

resource "aws_iam_role_policy_attachment" "test-attach1" {
  role       = aws_iam_role.SNSAccessForLamdaRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "test-attach2" {
  role       = aws_iam_role.SNSAccessForLamdaRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "test-attach3" {
  role       = aws_iam_role.SNSAccessForLamdaRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

# Create lambda_function
resource "aws_lambda_function" "InitializeUsers" {
  filename         = "InitializeUsers.zip"
  function_name    = "InitializeUsers"
  role             = aws_iam_role.SNSAccessForLamdaRole.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("InitializeUsers.zip")
  runtime          = "python3.7"
}

# Lambda_event from aws_dynamodb_table
resource "aws_lambda_event_source_mapping" "InitializeUsers" {
  event_source_arn  = aws_dynamodb_table.users.stream_arn
  function_name     = aws_lambda_function.InitializeUsers.arn
  starting_position = "LATEST"
}

# CloudWatch event rule and target for Lambda
resource "aws_cloudwatch_event_rule" "InitializeUsers" {
  name                = "InitializeUsers"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "InitializeUsers" {
  rule      = aws_cloudwatch_event_rule.InitializeUsers.name
  target_id = "InitializeUsers"
  arn       = aws_lambda_function.InitializeUsers.arn
}

# Lambda permission 
resource "aws_lambda_permission" "InitializeUsers" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.InitializeUsers.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.InitializeUsers.arn
}