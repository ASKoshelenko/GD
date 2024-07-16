# Create lambda_function
resource "aws_lambda_function" "ResendEmails" {
  filename         = "../lambda/ResendEmails.zip"
  function_name    = "ResendEmails"
  role             = aws_iam_role.ResendEmails.arn
  handler          = "ResendEmails.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/ResendEmails.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = "scenario1"
    }
  }
}

# Create IAM role
resource "aws_iam_role" "ResendEmails" {
  name = "ResendEmails"

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
resource "aws_iam_policy" "ResendEmails" {
  name   = "ResendEmails"
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
resource "aws_iam_role_policy_attachment" "resend-emails-ResendEmails" {
  role       = aws_iam_role.ResendEmails.name
  policy_arn = aws_iam_policy.ResendEmails.arn
}

resource "aws_iam_role_policy_attachment" "resend-emails-AmazonDynamoDBFullAccess" {
  role       = aws_iam_role.ResendEmails.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "resend-emails-AWSLambdaFullAccess" {
  role       = aws_iam_role.ResendEmails.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}
