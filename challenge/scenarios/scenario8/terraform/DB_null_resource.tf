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
          "scenarios.#scenario.#events = :e," ,
          "scenarios.#scenario.#ecr_repository_name = :ban,",
          "scenarios.#scenario.#git_repository_ip = :ipn,",
          "scenarios.#scenario.#targetdb_name = :dbn" ,

        "'",
        "--expression-attribute-names '{",
          "\"#scenario\"  :\"${var.scenario-name}\",",
          "\"#access_key\":\"access_key\",",
          "\"#secret_key\":\"secret_key\",",
          "\"#username\"  :\"username\",",
          "\"#events\"  :\"events\",",
          "\"#ecr_repository_name\"  :\"ecr_repository_name\",",
          "\"#git_repository_ip\"  :\"git_repository_ip\",",
          "\"#targetdb_name\"  :\"targetdb_name\"",
        "}'",
        "--expression-attribute-values '{",
          "\":a\":{\"S\":\"${aws_iam_access_key.user[count.index].id}\"},",
          "\":s\":{\"S\":\"${aws_iam_access_key.user[count.index].secret}\"},",
          "\":u\":{\"S\":\"${aws_iam_user.user[count.index].name}\"},",
          "\":e\":{\"L\":[]},",
          "\":ban\":{\"S\":\"${local.ecr_repository_name}-${local.users[count.index].userid}\"},",
          "\":ipn\":{\"S\":\"${aws_instance.dev.public_ip}\"},",
          "\":dbn\":{\"S\":\"${var.targetdb_name}-${local.users[count.index].userid}\"}",
        "}'",
        "--return-values UPDATED_NEW >> dbupdate.txt"
      ]) 
  }
}
