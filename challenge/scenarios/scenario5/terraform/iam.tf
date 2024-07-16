#IAM Users
resource "aws_iam_user" "user_scenario5_1" {
  count= length(local.users)
  name = "user_scenario5_1_${local.users[count.index].userid}"
  path  = "/${var.scenario-name}/"
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_iam_access_key" "scenario5_1_key" {
  count= length(local.users)
  user = aws_iam_user.user_scenario5_1[count.index].name
}

resource "aws_iam_user" "user_scenario5_2" {
  count= length(local.users)
  name = "user_scenario5_2_${local.users[count.index].userid}"
  path  = "/${var.scenario-name}/"
  tags = {
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}

resource "aws_iam_access_key" "scenario5_2_key" {
  count= length(local.users)
  user = aws_iam_user.user_scenario5_2[count.index].name
}

# IAM User Policies
resource "aws_iam_policy" "scenario5_1_policy" {
  name = "scenario5_1_policy"
  description = "scenario5_1_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.sc5-logs-s3-bucket.arn}",
        "${aws_s3_bucket.sc5-logs-s3-bucket.arn}/*"
        ]
    },
    {
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "rds:DescribeDBInstances",
        "elasticloadbalancing:DescribeLoadBalancers"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_policy" "scenario5_2_policy" {
  name = "scenario5_2_policy"
  description = "scenario5_2_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.sc5-keystore-s3-bucket.arn}",
        "${aws_s3_bucket.sc5-keystore-s3-bucket.arn}/*"
        ]
    },
    {
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "rds:DescribeDBInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# IAM User Policy Attachments
resource "aws_iam_user_policy_attachment" "user_scenario5_1_attachment" {
  count= length(local.users)
  user = aws_iam_user.user_scenario5_1[count.index].name
  policy_arn = aws_iam_policy.scenario5_1_policy.arn
}
resource "aws_iam_user_policy_attachment" "user_scenario5_2_attachment" {
  count= length(local.users)
  user = aws_iam_user.user_scenario5_2[count.index].name
  policy_arn = aws_iam_policy.scenario5_2_policy.arn
}
