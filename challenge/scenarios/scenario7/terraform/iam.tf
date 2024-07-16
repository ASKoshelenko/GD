#IAM User
resource "aws_iam_user" "user" {
  count = length(local.users)
  name = "${var.scenario-name}_${local.users[count.index].userid}"
  path = "/${var.scenario-name}/"
  tags = {
    Name     = "${var.scenario-name}_${local.users[count.index].userid}"
    Stack    = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_iam_access_key" "user" {
  count = length(local.users)
  user = aws_iam_user.user[count.index].name
}

# IAM roles
resource "aws_iam_role" "LambdaManager-role" {
  count = length(local.users)
  name = "${var.scenario-name}-LambdaManager-role-${local.users[count.index].userid}"
  path = "/${var.scenario-name}/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${aws_iam_user.user[count.index].arn}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "${var.scenario-name}-LambdaManager-role-${local.users[count.index].userid}"
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}

resource "aws_iam_role" "LambdaExecution-role" {
  count = length(local.users)
  name = "${var.scenario-name}-LambdaExecution-role-${local.users[count.index].userid}"
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
  tags = {
    Stack = "${var.stack-name}"
    Scenario = "${var.scenario-name}"
  }
}


# IAM Policies
resource "aws_iam_policy" "LambdaExecution-policy" {
  count = length(local.users)
  name = "${var.scenario-name}-LambdaExecution-policy-${local.users[count.index].userid}"
  policy =<<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Terraform0",
            "Effect": "Allow",
            "Action": "iam:AttachUserPolicy",
            "Resource": "${aws_iam_user.user[count.index].arn}",
            "Condition": {
              "StringEquals": {
              "iam:PolicyARN": "${aws_iam_policy.final_policy[count.index].arn}"
              }
            }
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
tags = {
    Name = "${var.scenario-name}-LambdaExecution-policy-${local.users[count.index].userid}"
    Stack = "${var.stack-name}"
  }
}

resource "aws_iam_policy" "LambdaManager-policy" {
  count = length(local.users)
  name = "${var.scenario-name}-LambdaManager-policy-${local.users[count.index].userid}"
  policy =<<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "lambdaManager",
            "Effect": "Allow",
            "Action": [
                "lambda:ListFunctions",
                "lambda:CreateFunction"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.region}"
                }
            }
        },
        {
            "Sid": "lambdaManagerRole",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "${aws_iam_role.LambdaExecution-role[count.index].arn}"
        },
        {
            "Sid": "LambdaInvoke",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction",
                "lambda:DeleteFunction"
            ],
            "Resource": "arn:aws:lambda:${var.region}:${data.aws_caller_identity.aws-account-id.account_id}:function:Sc7FinalLambda${local.users[count.index].userid}"
        }
    ]
}
EOF
tags = {
    Name = "${var.scenario-name}-LambdaManager-policy_${local.users[count.index].userid}"
    Stack = "${var.stack-name}"
  }
}

resource "aws_iam_policy" "user_policy" {
  count = length(local.users)
  name = "${var.scenario-name}-policy-${local.users[count.index].userid}"
  policy =<<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListPolicy",
            "Effect": "Allow",
            "Action": [
                "iam:List*",
                "iam:Get*"
            ],
            "Resource": "*"
        },
        { 
            "Sid": "AssumeRole",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
              "${aws_iam_role.LambdaManager-role[count.index].arn}"
            ]
        }
    ]
}
EOF
tags = {
    Stack = "${var.stack-name}"
  }
}
resource "aws_iam_policy" "final_policy"{
  count = length(local.users)
  name = "${var.scenario-name}-final-policy-${local.users[count.index].userid}"
  policy =<<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "Terraform0",
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:ListBucket"
          ],
          "Resource": [
            "${aws_s3_bucket.sc7-secret-s3-bucket.arn}",
            "${aws_s3_bucket.sc7-secret-s3-bucket.arn}/*"
          ]
        },
        {
          "Sid": "Terraform1",
          "Action": "s3:ListAllMyBuckets",
          "Effect": "Allow",
          "Resource": "*"
        }
    ]
}
EOF
tags = {
    Stack = "${var.stack-name}"
  }
}
#Policy Attachments
resource "aws_iam_role_policy_attachment" "LambdaExecution-roly-attachment" {
  count = length(local.users)
  role = aws_iam_role.LambdaExecution-role[count.index].name
  policy_arn = aws_iam_policy.LambdaExecution-policy[count.index].arn
}

resource "aws_iam_role_policy_attachment" "LambdaManager-role-attachment" {
  count = length(local.users)
  role = aws_iam_role.LambdaManager-role[count.index].name
  policy_arn = aws_iam_policy.LambdaManager-policy[count.index].arn
}

resource "aws_iam_user_policy_attachment" "user-attachment" {
  count = length(local.users)
  user = aws_iam_user.user[count.index].name
  policy_arn = aws_iam_policy.user_policy[count.index].arn
}
