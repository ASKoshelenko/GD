resource "null_resource" "update_dynamodb4" {
  count = length(local.users)
  provisioner "local-exec"{
      command = join(" ", [
        "aws dynamodb update-item",
        "--profile ${var.profile}",
        "--region ${var.region}",
        "--table-name ${var.dbName}",
        "--key '{\"userid\":{\"S\":\"${local.users[count.index].userid}\"}}'",
        "--update-expression 'SET scenarios.#scenario.#access_key_user1 = :a,",
          "scenarios.#scenario.#access_key_user2 = :b,",
          "scenarios.#scenario.#secret_key_user1 = :c,",
          "scenarios.#scenario.#secret_key_user2 = :d,",
          "scenarios.#scenario.#username_user1 = :e,",
          "scenarios.#scenario.#username_user2 = :f,",
          "scenarios.#scenario.#completion_key = :g,",
          "scenarios.#scenario.#user1_events = :k,",
          "scenarios.#scenario.#user2_events = :l,",
          "scenarios.#scenario.#target_lambda = :t'",
        "--expression-attribute-names '{",
          "\"#scenario\":\"${var.scenario-name}\",",
          "\"#access_key_user1\":\"access_key_user1\",",
          "\"#access_key_user2\":\"access_key_user2\",",
          "\"#secret_key_user1\":\"secret_key_user1\",",
          "\"#secret_key_user2\":\"secret_key_user2\",",
          "\"#username_user1\":\"username_user1\",",
          "\"#username_user2\":\"username_user2\",",
          "\"#completion_key\":\"completion_key\",",
          "\"#user1_events\":\"user1_events\",",
          "\"#user2_events\":\"user2_events\",",
          "\"#target_lambda\":\"target_lambda\"",
        "}'",
        "--expression-attribute-values '{",
          "\":a\":{\"S\":\"${aws_iam_access_key.scenario5_1_key[count.index].id}\"},",
          "\":b\":{\"S\":\"${aws_iam_access_key.scenario5_2_key[count.index].id}\"},",
          "\":c\":{\"S\":\"${aws_iam_access_key.scenario5_1_key[count.index].secret}\"},",
          "\":d\":{\"S\":\"${aws_iam_access_key.scenario5_2_key[count.index].secret}\"},",
          "\":e\":{\"S\":\"${aws_iam_user.user_scenario5_1[count.index].name}\"},",
          "\":f\":{\"S\":\"${aws_iam_user.user_scenario5_2[count.index].name}\"},",
          "\":g\":{\"S\":\"${local.users[count.index].userid}${random_id.secret_key[count.index].hex}\"},",
          "\":k\":{\"L\":[]},",
          "\":l\":{\"L\":[]},",
          "\":t\":{\"S\":\"${aws_lambda_function.sc5_complete[count.index].function_name}\"}",
        "}'",
        "--return-values UPDATED_NEW >> dbupdate.txt"
      ])
  }
}