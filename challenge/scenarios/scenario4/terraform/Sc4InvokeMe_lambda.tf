# data "archive_file" "sc4-lambda-function-invoke" {
#   type = "zip"
#   source_file = "../assets/InvokeMe.py"
#   output_path = "../assets/InvokeMe.zip"
# }
resource "aws_iam_role" "Sc4InvokeMe" {
  name = "Sc4InvokeMe-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }      
    }
  ]
}
EOF
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_iam_role_policy" "Sc4InvokeMe" {
  name   = "Sc4InvokeMe-policy"
  role = aws_iam_role.Sc4InvokeMe.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAuroraToExampleFunction",
            "Effect": "Allow",
            "Action": [ 
              "lambda:InvokeFunction",
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "${aws_lambda_function.Sc4FinCheck.arn}"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "Sc4InvokeMe" {
  filename = "../lambda/Sc4InvokeMe.zip"
  function_name = "Sc4InvokeMe"
  role = aws_iam_role.Sc4InvokeMe.arn
  handler = "Sc4InvokeMe.invoke_function"
  source_code_hash = filebase64sha256("../lambda/Sc4InvokeMe.zip")
  runtime = "python3.8"
  environment {
      variables = {
          EC2_ACCESS_KEY_ID = aws_iam_access_key.scenario4_2_user.id
          EC2_SECRET_KEY_ID = aws_iam_access_key.scenario4_2_user.secret
      }
  }
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}