resource "aws_iam_user" "user" {
  count = length(local.users)
  name  = "${var.scenario-name}_${local.users[count.index].userid}"
  path  = "/${var.scenario-name}/"
}

resource "aws_iam_access_key" "user-key" {
  count = length(local.users)
  user  = aws_iam_user.user[count.index].name
}

resource "aws_iam_policy" "user-policy" {
  count       = length(local.users)
  name        = "policy_${var.scenario-name}_${local.users[count.index].userid}"
  description = "users-policy"
  policy      = data.aws_iam_policy_document.v1[count.index].json
}

resource "aws_iam_user_policy" "inline"{
  count = length(local.users)
  name = "SetDefaultPolicyVersion"
  user = aws_iam_user.user[count.index].name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IAMPrivilegeEscalationByRollback",
      "Effect": "Allow",
      "Action": "iam:SetDefaultPolicyVersion",
      "Resource": "${aws_iam_policy.user-policy[count.index].arn}"
    }
  ]
}
EOF
}
resource "aws_iam_user_policy_attachment" "user-attachment" {
  count      = length(local.users)
  user       = aws_iam_user.user[count.index].name
  policy_arn = aws_iam_policy.user-policy[count.index].arn
}