# data "archive_file" "c-lambda-function" {
#   type = "zip"
#   source_file = "../lambda/Sc4FinCheck.py"
#   output_path = "../lambda/Sc4FinCheck.zip"
# }

#Create IAM role
resource "aws_iam_role" "Sc4FinCheck" {
  name = "Sc4FinCheck"
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

# Create Inline IAM policy 
resource "aws_iam_role_policy" "Sc4FinCheck" {
  name   = "Sc4FinCheck"
  role = aws_iam_role.Sc4FinCheck.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
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
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "dynamodb:GetItem",
            "Resource": "*"
        }
    ]
}
EOF
}

# Create lambda_function
resource "aws_lambda_function" "Sc4FinCheck" {
  filename = "../lambda/Sc4FinCheck.zip"
  function_name = "Sc4FinCheck"
  role = aws_iam_role.Sc4FinCheck.arn
  handler = "Sc4FinCheck.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc4FinCheck.zip")
  #  "${data.archive_file.c-lambda-function.output_base64sha256}"
  runtime = "python3.8"
  environment {
      variables = {
          ScenarioName = var.scenario-name
     }
  }
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }

}