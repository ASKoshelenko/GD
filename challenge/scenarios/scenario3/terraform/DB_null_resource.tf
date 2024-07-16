resource "random_integer" "priority" {
  count = length(local.users)
  min     = 1
  max     = 5
}


resource "null_resource" "update_dynamodb" {
  count = length(local.users)
  provisioner "local-exec"{
      command = join(" ", [
        "aws dynamodb update-item",
        "--profile ${var.profile}",
        "--region ${var.region}",
        "--table-name ${var.dbName}",
        "--key '{\"userid\":{\"S\":\"${local.users[count.index].userid}\"}}'",
        "--update-expression 'SET",
          "scenarios.#scenario.#access_key = :a, ",
          "scenarios.#scenario.#secret_key = :s, ",
          "scenarios.#scenario.#username   = :u, ",
          "scenarios.#scenario.#policy_arn = :p, ",
          "scenarios.#scenario.#target_id  = :i  ",
        "'",
        "--expression-attribute-names '{",
          "\"#scenario\"  :\"${var.scenario-name}\",",
          "\"#access_key\":\"access_key\",",
          "\"#secret_key\":\"secret_key\",",
          "\"#username\"  :\"username\",",
          "\"#policy_arn\":\"policy_arn\",",
          "\"#target_id\" :\"target_id\"",
        "}'",
        "--expression-attribute-values '{",
          "\":a\":{\"S\":\"${aws_iam_access_key.user-key[count.index].id}\"},",
          "\":s\":{\"S\":\"${aws_iam_access_key.user-key[count.index].secret}\"},",
          "\":u\":{\"S\":\"${aws_iam_user.user[count.index].name}\"},",
          "\":p\":{\"S\":\"${aws_iam_policy.user-termination-policy[count.index].arn}\"},",
          "\":i\":{\"S\":\"${aws_instance.ec2[count.index].id}\"}",
        "}'",
        "--return-values UPDATED_NEW >> dbupdate.txt"
      ]) 
  }
}
