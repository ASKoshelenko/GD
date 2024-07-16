resource "null_resource" "update_dynamodb" {
   count = length(var.email)
  provisioner "local-exec"{
      command = "aws dynamodb update-item --profile CG --table-name users --key '{\"email\":{\"S\":\"${var.email[count.index]}\"}}' --update-expression 'SET scenarios.#scenario.#access_key = :a' --expression-attribute-names '{\"#scenario\":\"first\",\"#access_key\":\"access_key\"}' --expression-attribute-values '{\":a\":{\"S\":\"${aws_iam_access_key.user[count.index].id}\"}}' --return-values UPDATED_NEW"
  }
}
resource "null_resource" "update_dynamodb1" {
   count = length(var.email)
  provisioner "local-exec"{
      command = "aws dynamodb update-item --profile CG --table-name users --key '{\"email\":{\"S\":\"${var.email[count.index]}\"}}' --update-expression 'SET scenarios.#scenario.#secret_key = :b' --expression-attribute-names '{\"#scenario\":\"first\",\"#secret_key\":\"secret_key\"}' --expression-attribute-values '{\":b\":{\"S\":\"${aws_iam_access_key.user[count.index].secret}\"}}' --return-values UPDATED_NEW"
  }
}
resource "null_resource" "update_dynamodb2" {
   count = length(var.email)
  provisioner "local-exec"{
      command = "aws dynamodb update-item --profile CG --table-name users --key '{\"email\":{\"S\":\"${var.email[count.index]}\"}}' --update-expression 'SET scenarios.#scenario.#name = :c' --expression-attribute-names '{\"#scenario\":\"first\",\"#name\":\"name\"}' --expression-attribute-values '{\":c\":{\"S\":\"${aws_iam_user.user[count.index].name}\"}}' --return-values UPDATED_NEW"
  }
}

  # aws dynamodb update-item --profile CG --table-name users --key '{"email":{"S":"abihirna@gmail.com"}}' --update-expression 'SET scenarios.#scenario.#access_key = :a' --expression-attribute-names '{"#scenario":"first","#access_key":"access_key"}' --expression-attribute-values '{":a":{"S":"key12346789"}}' --return-values UPDATED_NEW

  # aws dynamodb update-item --profile CG --table-name users --key '{"email":{"S":"abihirna@gmail.com"}}' --update-expression 'SET scenarios.#scenario.#secret_key = :b' --expression-attribute-names '{"#scenario":"first","#secret_key":"secret_key"}' --expression-attribute-values '{":b":{"S":"key112346789"}}' --return-values UPDATED_NEW
  
  # aws dynamodb update-item --profile CG --table-name users --key '{"email":{"S":"abihirna@gmail.com"}}' --update-expression 'SET scenarios.#scenario.#name = :c' --expression-attribute-names '{"#scenario":"first","#name":"name"}' --expression-attribute-values '{":c":{"S":"key112346789"}}' --return-values UPDATED_NEW
