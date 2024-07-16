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
          "scenarios.#scenario.#access_key = :a,",
          "scenarios.#scenario.#secret_key = :s,",
          "scenarios.#scenario.#username   = :u,",
          "scenarios.#scenario.#lambdaname = :l," ,
          "scenarios.#scenario.#events = :e," ,
          "scenarios.#scenario.#lambdaExecutioneRolearn = :m," ,
          "scenarios.#scenario.#policyarn = :p" ,

        "'",
        "--expression-attribute-names '{",
          "\"#scenario\"  :\"${var.scenario-name}\",",
          "\"#access_key\":\"access_key\",",
          "\"#secret_key\":\"secret_key\",",
          "\"#username\"  :\"username\",",
          "\"#lambdaname\"  :\"lambdaname\",",
          "\"#events\"  :\"events\",",
          "\"#lambdaExecutioneRolearn\"  :\"lambdaExecutioneRolearn\",",
          "\"#policyarn\"  :\"final_policy_arn\"",
        "}'",
        "--expression-attribute-values '{",
          "\":a\":{\"S\":\"${aws_iam_access_key.user[count.index].id}\"},",
          "\":s\":{\"S\":\"${aws_iam_access_key.user[count.index].secret}\"},",
          "\":u\":{\"S\":\"${aws_iam_user.user[count.index].name}\"},",
          "\":p\":{\"S\":\"${aws_iam_policy.final_policy[count.index].arn}\"},",
          "\":m\":{\"S\":\"${aws_iam_role.LambdaExecution-role[count.index].arn}\"},",
          "\":e\":{\"L\":[]},",
          "\":l\":{\"S\":\"Sc7FinalLambda${local.users[count.index].userid}\"}",
        "}'",
        "--return-values UPDATED_NEW >> dbupdate.txt"
      ]) 
  }
}
