# Create lambda_function
resource "aws_lambda_function" "ReplaceUser" {
  filename         = "../lambda/ReplaceUser.zip"
  function_name    = "ReplaceUser"
  role             = aws_iam_role.ReplaceUser.arn
  handler          = "ReplaceUser.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/ReplaceUser.zip")
  runtime          = "python3.9"
  timeout          = 900
  
}

# Create IAM role
resource "aws_iam_role" "ReplaceUser" {
  name = "ReplaceUser"

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
resource "aws_iam_policy" "ReplaceUser" {
  name   = "ReplaceUser"
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
resource "aws_iam_role_policy_attachment" "ReplaceUser" {
  role       = aws_iam_role.ReplaceUser.name
  policy_arn = aws_iam_policy.ReplaceUser.arn
}

resource "aws_iam_role_policy_attachment" "ReplaceUser-AmazonDynamoDBFullAccess" {
  role       = aws_iam_role.ReplaceUser.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

