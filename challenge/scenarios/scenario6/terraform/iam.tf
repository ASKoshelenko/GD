#Creat IAM Users
resource "aws_iam_user" "user_scenario6_1" {
  count = length(local.users)
  name  = "user_scenario6_1_${local.users[count.index].userid}"
  path  = "/${var.scenario-name}/"
  tags = {
    Name     = "user_scenario6_1_${local.users[count.index].userid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_iam_access_key" "scenario6_1" {
  count = length(local.users)
  user  = aws_iam_user.user_scenario6_1[count.index].name
}

resource "aws_iam_user" "user_scenario6_2" {
  path  = "/${var.scenario-name}/"
  count = length(local.users)
  name  = "user_scenario6_2_${local.users[count.index].userid}"
  tags = {
    Name     = "user_scenario6_2_${local.users[count.index].userid}"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_iam_access_key" "scenario6_2" {
  count = length(local.users)
  user  = aws_iam_user.user_scenario6_2[count.index].name
}

#IAM User Policies
resource "aws_iam_user_policy" "scenario6_1_policy" {
  count  = length(local.users)
  name   = "scenario6_1_policy_${local.users[count.index].userid}"
  user   = aws_iam_user.user_scenario6_1[count.index].name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "scenario61",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "ssm:DescribeParameters",
                "codebuild:ListProjects",
                "codebuild:ListBuilds",
                "ec2:DescribeInstances",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        },
        {
            "Sid": "scenario62",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": [
                "${aws_ssm_parameter.sc6-ec2-private-key.arn}",
                "${aws_ssm_parameter.sc6-ec2-public-key.arn}"
            ]
        },
        {
            "Sid": "scenario63",
            "Effect": "Allow",
            "Action": "codebuild:BatchGetProjects",
            "Resource": "${aws_codebuild_project.sc6-codebuild-project[count.index].arn}"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy" "scenario6_2_policy" {
  count  = length(local.users)
  name   = "scenario6_2_policy_${local.users[count.index].userid}"
  user   = aws_iam_user.user_scenario6_2[count.index].name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Terraform",
            "Effect": "Allow",
            "Action": [
                "rds:CreateDBSnapshot",
                "rds:DescribeDBInstances",
                "rds:DescribeDBSubnetGroups",
                "rds:CreateDBSecurityGroup",
                "rds:DescribeDBSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Terraform1",
            "Effect": "Allow",
            "Action": "rds:RestoreDBInstanceFromDBSnapshot",
            "Resource": [
                "arn:aws:rds:*:*:snapshot:*",
                "arn:aws:rds:eu-central-1:*:db:${local.users[count.index].userid}-database",
                "arn:aws:rds:*:*:subgrp:*",
                "arn:aws:rds:*:*:og:*"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "rds:DatabaseClass": "db.t3.micro"
                }
            }
        },
        {
            "Sid": "Terraform2",
            "Effect": "Allow",
            "Action": "rds:DeleteDBInstance",
            "Resource": "arn:aws:rds:eu-central-1:*:db:${local.users[count.index].userid}-database"
        },
        {
            "Sid": "Terraform3",
            "Effect": "Allow",
            "Action": "rds:ModifyDBInstance",
            "Resource": [
                "arn:aws:rds:eu-central-1:*:db:${local.users[count.index].userid}-database",
                "arn:aws:rds:*:*:secgrp:*",
                "arn:aws:rds:*:*:og:*",
                "arn:aws:rds:*:*:pg:*"
            ]
        }
    ]
}
EOF
}
