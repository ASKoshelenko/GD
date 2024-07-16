resource "aws_iam_user" "user" {
  count = length(local.users)
  name = "${var.scenario-name}_${local.users[count.index].userid}"
  path = "/${var.scenario-name}/"
}
resource "aws_iam_user_policy" "user-policy" {
  count = length(local.users)
  user = aws_iam_user.user[count.index].name
  name = "${var.scenario-name}-user-policy-${local.users[count.index].userid}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:Get*",
                "iam:List*",
                "ssm:DescribeParameters",
                "ssm:ListTagsForResource",
                "ssm:GetParameters"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:${var.region}:${local.account_id}:parameter/git_access_key_for_sc8_ro_user_${local.users[count.index].userid}",
            "Condition": {
                "StringLike": {
                    "ssm:resourceTag/Environment": "sandbox"
                }
            }
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "ssm:RemoveTagsFromResource",
                "ssm:AddTagsToResource"
            ],
            "Resource": "arn:aws:ssm:${var.region}:${local.account_id}:parameter/git_access_key_for_sc8_ro_user_${local.users[count.index].userid}",
            "Condition": {
                "StringLike": {
                    "ssm:resourceTag/Environment": "dev"
                }
            }
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": "sts:GetFederationToken",
            "Resource": [
                "arn:aws:ssm:${var.region}:${local.account_id}:parameter/git_access_key_for_sc8_ro_user_${local.users[count.index].userid}",
                "arn:aws:sts::${local.account_id}:federated-user/${aws_iam_user.user[count.index].name}"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_access_key" "user" {
  count = length(local.users)
  user = aws_iam_user.user[count.index].name
}