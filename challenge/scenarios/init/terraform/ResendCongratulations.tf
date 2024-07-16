# Create lambda_function
resource "aws_lambda_function" "ResendCongratulations" {
  filename         = "../lambda/ResendCongratulations.zip"
  function_name    = "ResendCongratulations"
  role             = aws_iam_role.ResendCongratulations.arn
  handler          = "ResendCongratulations.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/ResendCongratulations.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = "scenario1"
    }
  }
}

# Create IAM role
resource "aws_iam_role" "ResendCongratulations" {
  name = "ResendCongratulations"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
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

# Create Inline IAM policy for Cloud Watch
resource "aws_iam_policy" "ResendCongratulations" {
  name   = "ResendCongratulations"
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
resource "aws_iam_role_policy_attachment" "resend-emails-congrat-ResendCongratulations1" {
  role       = aws_iam_role.ResendCongratulations.name
  policy_arn = aws_iam_policy.ResendCongratulations.arn
}

resource "aws_iam_role_policy_attachment" "resend-emails-congrat-AmazonDynamoDBFullAccess" {
  role       = aws_iam_role.ResendCongratulations.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "resend-emails-congrat-ResendCoAWSLambdaFullAccessngratulations3" {
  role       = aws_iam_role.ResendCongratulations.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}
