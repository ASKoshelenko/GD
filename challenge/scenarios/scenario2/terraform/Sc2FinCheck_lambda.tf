# Sc2FinCheck policy
resource "aws_iam_role_policy" "Sc2FinCheck" {
  name = "Sc2FinCheck"
  role = aws_iam_role.Sc2FinCheck.id
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
                "lambda:InvokeFunction",
                "dynamodb:Scan",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Sc2FinCheck role
resource "aws_iam_role" "Sc2FinCheck" {
  name = "Sc2FinCheck"
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

resource "aws_lambda_function" "Sc2FinCheck" {
  count= length(local.users)
  filename      = "../lambda/Sc2FinCheck.zip"
  function_name = "Sc2FinCheck_${local.users[count.index].userid}"
  role          = aws_iam_role.Sc2FinCheck.arn
  handler       = "Sc2FinCheck.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/Sc2FinCheck.zip")
  runtime = "python3.8"
  environment {
    variables = {
      UserEmail = local.users[count.index].email,
      ScenarioName = var.scenario-name,
      UserName = local.users[count.index].userid
    }
  }
}
