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
        "scenarios.#scenario.#access_key       = :a, ",
        "scenarios.#scenario.#secret_key       = :s, ",
        "scenarios.#scenario.#username         = :u, ",
        "scenarios.#scenario.#target_ip        = :i, ",
        "scenarios.#scenario.#completion_key   = :k, ",
        "scenarios.#scenario.#target_lambda    = :l  ",
      "'",
      "--expression-attribute-names '{",
        "\"#scenario\"       :\"${var.scenario-name}\",",
        "\"#access_key\"     :\"access_key\",",
        "\"#secret_key\"     :\"secret_key\",",
        "\"#username\"       :\"username\",",
        "\"#target_ip\"      :\"target_ip\",",
        "\"#completion_key\" :\"completion_key\",",
        "\"#target_lambda\"  :\"target_lambda\"",
      "}'",
      "--expression-attribute-values '{",
        "\":a\":{\"S\":\"${aws_iam_access_key.user-key[count.index].id}\"},",
        "\":s\":{\"S\":\"${aws_iam_access_key.user-key[count.index].secret}\"},",
        "\":u\":{\"S\":\"${aws_iam_user.user[count.index].name}\"},",
        "\":i\":{\"S\":\"${aws_instance.ec2.public_ip}\"},",
        "\":k\":{\"S\":\"${local.codes[count.index]}\"},",
        "\":l\":{\"S\":\"${aws_lambda_function.Sc2FinCheck[count.index].function_name}\"}",
      "}'",
      "--return-values UPDATED_NEW >> dbupdate.txt"])
  }
}
