# IAM Users 4_1
resource "aws_iam_user" "scenario4_1_user" {
  count= length(local.users)
  name = "scenario4_1_user_${local.users[count.index].userid}"
  path  = "/${var.scenario-name}/"
  tags = {
    Name = "scenario4_1_user-${local.users[count.index].userid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_iam_access_key" "scenario4_1_user" {
  count= length(local.users)
  user = aws_iam_user.scenario4_1_user[count.index].name
}

# IAM Users 4_2
resource "aws_iam_user" "scenario4_2_user" {
  name = "scenario4_2_user"
  path  = "/${var.scenario-name}/"
  tags = {
    Name = "scenario4_2_user"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_iam_access_key" "scenario4_2_user" {
  user = aws_iam_user.scenario4_2_user.name
}

# IAM Users 4_3
resource "aws_iam_user" "scenario4_3_user" {
  name = "scenario4_3_user"
  path  = "/${var.scenario-name}/"
  tags = {
    Name = "scenario4_3_user"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_iam_access_key" "scenario4_3_user" {
  user = aws_iam_user.scenario4_3_user.name
}

# IAM User Policies
resource "aws_iam_policy" "scenario4_1_user-policy" {
  description = "IAM_group_scenario4"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "s",
            "Effect": "Allow",
            "Action": [
                "lambda:GetFunction"
            ],
            "Resource": "${aws_lambda_function.Sc4InvokeMe.arn}"
        },
        {
            "Sid": "s1",
            "Effect": "Allow",
            "Action": [
                "lambda:ListFunctions"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "scenario4_2_user-policy" {
  name = "scenario4_2_user-policy"
  description = "scenario4_2_user-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeIamInstanceProfileAssociations",
            "ec2:DescribeInstances"
          ],
          "Resource": "*"
        }
    ]
}

EOF
}

resource "aws_iam_policy" "scenario4_3_user-policy" {
  name = "scenario4_3_user-policy"
  description = "scenario4_3_user-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": [
        "lambda:GetFunction",
        "lambda:InvokeFunction",
        "lambda:ListFunction"
      ],
      "Resource": [ 
        "${aws_s3_bucket.sc4-secret-s3-bucket.arn}",
        "${aws_lambda_function.Sc4InvokeMe.arn}"
      ]
    }
  ]
}
EOF
}

#User Policy Attachments
resource "aws_iam_user_policy_attachment" "scenario4_1-attachment" {
  count = length(local.users)
  user = aws_iam_user.scenario4_1_user[count.index].name
  policy_arn = aws_iam_policy.scenario4_1_user-policy.arn
}

resource "aws_iam_user_policy_attachment" "scenario4_2_user-attachment" {
  user = aws_iam_user.scenario4_2_user.name
  policy_arn = aws_iam_policy.scenario4_2_user-policy.arn
}

resource "aws_iam_user_policy_attachment" "scenario4_3_user-attachment" {
  user = aws_iam_user.scenario4_3_user.name
  policy_arn = aws_iam_policy.scenario4_3_user-policy.arn
}