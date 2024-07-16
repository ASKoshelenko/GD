# Create lambda_function
resource "aws_lambda_function" "ResultLambda" {
  filename         = "../resultlambda/ResultLambda.zip"
  function_name    = "ResultLambda"
  role             = aws_iam_role.ResultLambda.arn
  handler          = "ResultLambda.lambda_handler"
  source_code_hash = filebase64sha256("../resultlambda/ResultLambda.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      StartTime = "2023-06-04T16:00:00Z"
      BucketName = var.result_bucket_name
    }
  }
}

# Create IAM role
resource "aws_iam_role" "ResultLambda" {
  name = "ResultLambdaRole"

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
resource "aws_iam_policy" "ResultLambda" {
  name   = "ResultLambda"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DynamoDBAccess",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": "arn:aws:dynamodb:eu-central-1:553396899541:table/users"
        },
        {
            "Sid": "S3Access",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::${var.result_bucket_name}/*"
        }
    ]
}
EOF
}

# Block policy_attachment
resource "aws_iam_role_policy_attachment" "result-ResultLambda" {
  role       = aws_iam_role.ResultLambda.name
  policy_arn = aws_iam_policy.ResultLambda.arn
}
