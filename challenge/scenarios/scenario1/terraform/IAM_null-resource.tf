resource "null_resource" "create-iam-user-policy-version-2" {
  count = length(local.users)
  provisioner "local-exec" {
    command = join(" ", [
      "aws iam create-policy-version",
      "--policy-arn ${aws_iam_policy.user-policy[count.index].arn}",
      "--policy-document '${data.aws_iam_policy_document.v2[count.index].json}'",
      "--no-set-as-default",
      "--profile ${var.profile}",
      " --region ${var.region}"
    ])
  }
}
resource "null_resource" "create-iam-user-policy-version-3" {
  count = length(local.users)
  provisioner "local-exec" {
    command = join(" ", [
      "aws iam create-policy-version",
      "--policy-arn ${aws_iam_policy.user-policy[count.index].arn}",
      "--policy-document '${data.aws_iam_policy_document.v3[count.index].json}'",
      "--no-set-as-default",
      "--profile ${var.profile}",
      " --region ${var.region}"
    ])
  }
}
resource "null_resource" "create-iam-user-policy-version-4" {
  count = length(local.users)
  provisioner "local-exec" {
    command = join(" ", [
      "aws iam create-policy-version",
      "--policy-arn ${aws_iam_policy.user-policy[count.index].arn}",
      "--policy-document '${data.aws_iam_policy_document.v4[count.index].json}'",
      "--no-set-as-default",
      "--profile ${var.profile}",
      " --region ${var.region}"
    ])
  }
}
resource "null_resource" "create-iam-user-policy-version-5" {
  count = length(local.users)
  provisioner "local-exec" {
    command = join(" ", [
      "aws iam create-policy-version",
      "--policy-arn ${aws_iam_policy.user-policy[count.index].arn}",
      "--policy-document '${data.aws_iam_policy_document.v5[count.index].json}'",
      "--no-set-as-default",
      "--profile ${var.profile}",
      " --region ${var.region}"
    ])
  }
}
