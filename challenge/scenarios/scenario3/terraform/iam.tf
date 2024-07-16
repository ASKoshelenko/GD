# IAM Users
resource "aws_iam_user" "user" {
  count= length(local.users)
  name = "${var.scenario-name}_${local.users[count.index].userid}"
  path  = "/${var.scenario-name}/"
  tags = {
    Name = "${var.scenario-name}_${local.users[count.index].userid}"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
# IAM users' access key
resource "aws_iam_access_key" "user-key" {
  count= length(local.users)
  user = aws_iam_user.user[count.index].name
}
# IAM User Policies
resource "aws_iam_user_policy" "user-policy" {
  count= length(local.users)
  name = "policy_sc3_${local.users[count.index].userid}"
  user = aws_iam_user.user[count.index].name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Terraform",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:AddRoleToInstanceProfile"
      ],
      "Resource": [
        "${aws_iam_role.ec2-deletion-role[count.index].arn}",
        "${aws_iam_role.ec2-meek-role.arn}",
        "${aws_iam_instance_profile.ec2-meek-instance-profile[count.index].arn}"
      ]
    },
    {
      "Sid": "Terraform1",
      "Effect": "Allow",
      "Action": [
        "iam:ListRoles",
        "iam:GetRole",          
        "iam:ListInstanceProfiles",
        "ec2:AssociateIamInstanceProfile",
        "ec2:DescribeIamInstanceProfileAssociations",
        "ec2:DescribeInstances",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:CreateKeyPair",
        "ec2:CreateTags"
      ],
      "Resource": "*"      
    },
    {
      "Sid": "Terraform2",
      "Action": "ec2:RunInstances",
      "Effect": "Allow",
      "Resource": "*",
      "Condition": {
        "ForAllValues:StringEquals": {
          "ec2:InstanceType": [
            "t3.micro",
            "t3.nano"
          ]
        }
      }
    },  
    {
        "Sid": "Terraform3",
        "Effect": "Allow",
        "Action": "iam:GetInstanceProfile",
        "Resource": "${aws_iam_instance_profile.ec2-meek-instance-profile[count.index].arn}"
    }
  ]
}
EOF
}

# IAM User Policies
resource "aws_iam_policy" "user-termination-policy" {
  count = length(local.users)
  name = "ec2-termination-policy_${local.users[count.index].userid}"
  description = "${var.scenario-name}ec2-termination-policy_${local.users[count.index].userid}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Terraform",
      "Effect": "Allow",
      "Action": "ec2:TerminateInstances",
      "Resource": [
        "arn:aws:ec2:eu-central-1:*:instance/i-12345678901234568"
      ]
    }
  ]
}
EOF
}

# IAM Role for EC2 Mighty
resource "aws_iam_role" "ec2-deletion-role" {
  count= length(local.users)
  name = "ec2-deletion-role_${local.users[count.index].userid}"
  path  = "/${var.scenario-name}/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = {
      Name = "${var.scenario-name} EC2 Mighty Role ${local.users[count.index].userid}"
      Stack = var.stack-name
  }
}
# IAM Role for EC2 Meek
resource "aws_iam_role" "ec2-meek-role" {
  name = "ec2-meek-role"
  path  = "/${var.scenario-name}/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = {
      Name = "${var.scenario-name} EC2 Meek Role"
      Stack = var.stack-name
      Tip = "Swap me in your instance profile with your personal role with name ec2-deletion-role_Name_Surname"
  }
}
#IAM Policy for EC2 Mighty
resource "aws_iam_policy" "ec2-deletion-policy" {
  count= length(local.users)
  name = "ec2-deletion-policy_${local.users[count.index].userid}"
  description = "ec2-deletion-policy"
  policy =  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:ModifyInstanceAttribute",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:TerminateInstances",
      "Resource": "${aws_instance.ec2[count.index].arn}"
    }
  ]
}
EOF
}

#IAM Policy for EC2 meek
resource "aws_iam_policy" "ec2-meek-policy" {
  name = "ec2-meek-policy"
  description = "ec2-meek-policy"
  policy =  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Deny",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "termination-user-policy-attachment" {
  count= length(local.users)
  user = aws_iam_user.user[count.index].name
  policy_arn = aws_iam_policy.user-termination-policy[count.index].arn
}


# IAM Role Policy Attachment for EC2 Mighty
resource "aws_iam_role_policy_attachment" "ec2-deletion-role-policy-attachment" {
  count= length(local.users)
  role = aws_iam_role.ec2-deletion-role[count.index].name
  policy_arn = aws_iam_policy.ec2-deletion-policy[count.index].arn
}

# IAM Role Policy Attachment for EC2 Meek
resource "aws_iam_role_policy_attachment" "ec2-meek-role-policy-attachment" {
  role = aws_iam_role.ec2-meek-role.name
  policy_arn = aws_iam_policy.ec2-meek-policy.arn
}

# IAM Instance Profile for Meek EC2 instances
resource "aws_iam_instance_profile" "ec2-meek-instance-profile" {
  count = length(local.users)
  name = "ec2-meek-instance-profile_${local.users[count.index].userid}"
  role = aws_iam_role.ec2-meek-role.name
}