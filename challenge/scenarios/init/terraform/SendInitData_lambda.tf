# Create lambda_function
resource "aws_lambda_function" "SendInitData" {
  filename         = "../lambda/SendInitData.zip"
  function_name    = "SendInitData"
  role             = aws_iam_role.SendInitData.arn
  handler          = "SendInitData.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/SendInitData.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = "scenario1"
    }
  }
}

# Create IAM role
resource "aws_iam_role" "SendInitData" {
  name = "SendInitData"

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
resource "aws_iam_policy" "SendInitData" {
  name   = "SendInitData"
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
resource "aws_iam_role_policy_attachment" "send-init-data-SendInitData" {
  role       = aws_iam_role.SendInitData.name
  policy_arn = aws_iam_policy.SendInitData.arn
}

resource "aws_iam_role_policy_attachment" "send-init-data-AmazonDynamoDBFullAccess" {
  role       = aws_iam_role.SendInitData.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "send-init-data-AWSLambda_FullAccess" {
  role       = aws_iam_role.SendInitData.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}
