/*
resource "aws_iam_user" "developer" {
  count = length(local.users)
  name = "${local.repo_readwrite_username}_${local.users[count.index].userid}"
}
resource "aws_iam_user_policy" "developer" {
  count = length(local.users)
  name = "developer-policy-${local.users[count.index].userid}"
  user = aws_iam_user.developer[count.index].name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
          "codebuild:List*",
          "codebuild:BatchGetProjects",
          "codebuild:BatchGetBuilds",
          "codepipeline:List*",
          "codepipeline:Get*",
          "codedeploy:List*",
          "logs:Get*",
          "logs:Describe*"
      ]
    },
    {
      "Effect": "Deny",
      "Resource": "${aws_codebuild_project.acceptance-test[count.index].arn}",
      "Action": [
          "*"
      ]
    },
    {
      "Effect": "Allow",
      "Sid": "AllowConsoleAccess",
      "Resource": "arn:aws:sts::${local.account_id}:federated-user/${aws_iam_user.developer[count.index].name}",
      "Action": "sts:GetFederationToken"
    }
  ]
}
POLICY
}

resource "aws_iam_access_key" "developer" {
  count = length(local.users)
  user = aws_iam_user.developer[count.index].name
}
*/