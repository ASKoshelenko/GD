resource "tls_private_key" "ssh_key" {
  count = length(local.users)
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_ssm_parameter" "git_access_key" {
  count = length(local.users)
  name  = "git_access_key_for_sc8_ro_user_${local.users[count.index].userid}"
  description = "The private key for access to repository git@${aws_instance.dev.public_ip}:root/${var.scenario-name}_${local.users[count.index].userid}.git"
  type  = "String"
  value = tls_private_key.ssh_key[count.index].private_key_openssh
  tags = {
    Environment = "dev"
  }
}
/*
# IAM user
resource "aws_iam_user" "readonly_user" {
  count = length(local.users)
  name = "${local.repo_readonly_username}_${local.users[count.index].userid}"
}
resource "aws_iam_user_ssh_key" "readonly_user" {
  count = length(local.users)
  username   = aws_iam_user.readonly_user[count.index].name
  encoding   = "SSH"
  public_key = tls_private_key.ssh_key[count.index].public_key_openssh
}
resource "aws_iam_user_policy" "readonly_user" {
  count = length(local.users)
  name = "readonly_user-policy_${local.users[count.index].userid}"
  user = aws_iam_user.readonly_user[count.index].name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
          "codecommit:Get*",
          "codecommit:List*"
      ]
    }
  ]
}
POLICY

}
*/
locals {
  keys_array = [
     for i in range(length(local.users)):    
        chomp(tls_private_key.ssh_key[i].public_key_openssh)
  ] 
}