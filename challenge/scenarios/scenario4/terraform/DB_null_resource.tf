resource "null_resource" "update_dynamodb4" {
   count = length(local.users)
   provisioner "local-exec"{
      command = join(" ", [
        "aws dynamodb update-item",
        "--profile ${var.profile}",
        "--region ${var.region}",
        "--table-name ${var.dbName}",
        "--key '{\"userid\":{\"S\":\"${local.users[count.index].userid}\"}}'",
        "--update-expression 'SET", 
          "scenarios.#scenario.#access_key = :a,",
          "scenarios.#scenario.#secret_key = :c,",
          "scenarios.#scenario.#completion = :k,",
          "scenarios.#scenario.#username = :e,",
          "scenarios.#scenario.#target_lambda = :t'",
        "--expression-attribute-names '{",
          "\"#scenario\":\"${var.scenario-name}\",",
          "\"#access_key\":\"access_key\",",
          "\"#secret_key\":\"secret_key\",",
          "\"#completion\":\"target_key\",",
          "\"#username\":\"username\",",
          "\"#target_lambda\":\"target_lambda\"",
        "}'",
        "--expression-attribute-values '{",
          "\":a\":{\"S\":\"${aws_iam_access_key.scenario4_1_user[count.index].id}\"},",        
          "\":c\":{\"S\":\"${aws_iam_access_key.scenario4_1_user[count.index].secret}\"},",
          "\":k\":{\"S\":\"${local.codes[count.index]}\"},",
          "\":e\":{\"S\":\"${aws_iam_user.scenario4_1_user[count.index].name}\"},",
          "\":t\":{\"S\":\"${aws_lambda_function.Sc4InvokeMe.function_name}\"}",
        "}'",
        "--return-values UPDATED_NEW >> dbupdate.txt"
      ])
  }
}
 