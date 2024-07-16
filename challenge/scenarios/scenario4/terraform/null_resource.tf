#Null Resources
resource "null_resource" "sc4-create-latest-passwords-list-file" {
  provisioner "local-exec" {
      command = "touch ../assets/latest-passwords-list.txt"
  }
}
resource "null_resource" "sc4-create-sheperds-credentials-file" {
  provisioner "local-exec" {
      command = join(" ",[
      "touch ../assets/admin-user.txt",
      "&& echo ${aws_iam_access_key.scenario4_3_user.id} >>../assets/admin-user.txt",
      "&& echo ${aws_iam_access_key.scenario4_3_user.secret} >>../assets/admin-user.txt"
      ])
  }
}