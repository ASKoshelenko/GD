resource "null_resource" "cg-create-iam-user-policy-version-2" {
  count = length(var.user)
  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.user_po[count.index].arn} --policy-document file://./assets/policies/v2.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
resource "null_resource" "cg-create-iam-user-policy-version-3" {
  count = length(var.user)
  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.user_po[count.index].arn} --policy-document file://./assets/policies/v3.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
resource "null_resource" "cg-create-iam-user-policy-version-4" {
  count = length(var.user)
  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.user_po[count.index].arn} --policy-document file://./assets/policies/v4.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
resource "null_resource" "cg-create-iam-user-policy-version-5" {
  count = length(var.user)
  provisioner "local-exec" {
    command = "aws iam create-policy-version --policy-arn ${aws_iam_policy.user_po[count.index].arn} --policy-document file://./assets/policies/v5.json --no-set-as-default --profile ${var.profile} --region ${var.region}"
  }
}
