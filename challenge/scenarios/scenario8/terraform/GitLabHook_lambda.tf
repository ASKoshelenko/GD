resource "aws_iam_role" "GitLabHook" {
  name = "GitLabHook-role"
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
    Scenario = var.scenario-name
  }
}
resource "aws_iam_role_policy" "GitLabHook" {
  name   = "GitLabHook-policy"
  role = aws_iam_role.GitLabHook.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution",
                "codebuild:StartBuild"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [ 
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "GitLabHook" {
  filename = "../lambda/GitLabHook.zip"
  function_name = "GitLabHook"
  role = aws_iam_role.GitLabHook.arn
  handler = "GitLabHook.invoke_function"
  source_code_hash = filebase64sha256("../lambda/GitLabHook.zip")
  runtime = "python3.8"
  environment {
      variables = {
          SCENARIO = var.scenario-name
      }
  }
  tags = {
    Scenario = var.scenario-name
  }
}

resource "aws_lambda_function_url" "GitLabHook" {
  function_name      = aws_lambda_function.GitLabHook.arn
  authorization_type = "NONE"
}



/*
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution",
                "codebuild:StartBuild"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-central-1:820604685737:*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:eu-central-1:820604685737:log-group:/aws/lambda/GitLabListener:*"
        }
    ]
}

*/