# Policy for finalizing lambda of scenario5
resource "aws_iam_role_policy" "sc5_complete" {
  name = "sc5_complete"
  role = aws_iam_role.sc5_complete.id
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
                "sns:Publish",
                "cloudtrail:LookupEvents",
                "dynamodb:Scan",
                "dynamodb:GetItem",
                "lambda:InvokeFunction",
                "dynamodb:UpdateItem"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "sc5_complete" {
  name = "sc5_complete"
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

resource "aws_lambda_function" "sc5_complete" {
  count= length(local.users)
  filename         = "../lambda/sc5_complete.zip"
  function_name    = "sc5_complete_${local.users[count.index].userid}"
  role             = aws_iam_role.sc5_complete.arn
  handler          = "sc5_complete.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/sc5_complete.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      UserEmail = local.users[count.index].email,
      UserName = local.users[count.index].userid,
      ScenarioName = var.scenario-name
    }
  }
}

resource "aws_iam_user_policy" "complete_lambda_invoke" {
  count= length(local.users)
  name = "${var.scenario-name}_lambda_invoke_policy_${local.users[count.index].userid}"
  user = aws_iam_user.user_scenario5_1[count.index].name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.sc5_complete[count.index].arn}"
    }
  ]
}
EOF
}
