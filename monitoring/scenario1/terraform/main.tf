resource "aws_iam_user" "user" {
  count = length(var.user)
  name  = var.user[count.index]
  path  = "/system/"
}

resource "aws_iam_access_key" "user" {
  count = length(var.user)
  user  = aws_iam_user.user[count.index].name
}

resource "aws_iam_policy" "user_po" {
  count       = length(var.user)
  name        = "policy_cgsc1_${var.user[count.index]}"
  description = "user-policy"
  policy      = file("./assets/policies/v1.json")
}

resource "aws_iam_user_policy_attachment" "user-attachment" {
  count      = length(var.user)
  user       = aws_iam_user.user[count.index].name
  policy_arn = aws_iam_policy.user_po[count.index].arn
}