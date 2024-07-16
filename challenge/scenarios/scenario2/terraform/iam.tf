
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

resource "aws_iam_access_key" "user-key" {
  count= length(local.users)
  user = aws_iam_user.user[count.index].name
}

resource "aws_iam_user_policy" "user-policy" {
  count= length(local.users)
  name = "${var.scenario-name}_${local.users[count.index].userid}_inline"
  user = aws_iam_user.user[count.index].name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.Sc2FinCheck[count.index].arn}"
    }
  ]
}
EOF
}