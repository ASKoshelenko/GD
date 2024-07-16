/*
resource "aws_codecommit_repository" "code" {
  count = length(local.users)
  repository_name = "${local.repository_name}-${local.users[count.index].userid}"
}
*/
locals {
 // Note: templatefile only works if the template is in the Terraform folder
  app_file_content_array = [
     for i in range(length(aws_dynamodb_table.targetdb)):
        templatefile("${path.module}/app.py.tftpl", {
            aws_targetdb_name     = aws_dynamodb_table.targetdb[i].name,
        })
  ] 

  src_path = "${abspath(path.module)}/../assets/src"
}

resource "null_resource" "create_files" {
  count = length(local.users)
  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    interpreter = ["bash", "-c"]
    
    command     = <<BASH
    set -e
    cat > "${local.src_path}/app${count.index}.py" <<EOF
${local.app_file_content_array[count.index]}
EOF
BASH
  }


}
/*
resource "null_resource" "upload_files" {
  depends_on = [
    aws_iam_role_policy.build-docker-image,
    aws_codecommit_repository.code,
    null_resource.create_files,
  ]

  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    interpreter = ["bash", "-c"]
    environment = {
      AWS_REGION = var.region,
      AWS_DEFAULT_REGION = var.region
      USERS_COUNT = length(local.users)
    }
    
    command     = <<BASH
    set -e

    for (( i=0; i < $USERS_COUNT; i++))

    do 

      userid=$(grep -Po -e "targetdb-\K.*?(?=')" ${local.src_path}/app$i.py)

      commit=$(aws codecommit put-file --repository-name ${local.repository_name}-$userid --branch-name master --file-content fileb://${local.src_path}/buildspec$i.old.yml --file-path buildspec.yml --output text --query commitId --profile ${var.profile});
      commit=$(aws codecommit put-file --repository-name ${local.repository_name}-$userid --branch-name master --file-content fileb://${local.src_path}/buildspec.yml --file-path buildspec.yml --commit-message "Use built-in AWS authentication instead of hardcoded keys" --parent-commit-id $commit --output text --query commitId --profile ${var.profile});
      commit=$(aws codecommit put-file --repository-name ${local.repository_name}-$userid --branch-name master --file-content fileb://${local.src_path}/Dockerfile --file-path Dockerfile --parent-commit-id $commit --output text --query commitId --profile ${var.profile});
      commit=$(aws codecommit put-file --repository-name ${local.repository_name}-$userid --branch-name master --file-content fileb://${local.src_path}/requirements.txt --file-path requirements.txt --parent-commit-id $commit --output text --query commitId --profile ${var.profile});
      commit=$(aws codecommit put-file --repository-name ${local.repository_name}-$userid --branch-name master --file-content fileb://${local.src_path}/app$i.py --file-path app.py --parent-commit-id $commit --output text --query commitId --profile ${var.profile});    

    done
BASH
  }


}
*/
resource "null_resource" "create_image" {
  depends_on = [
    aws_codebuild_project.build-docker-image,
    aws_iam_role_policy.build-docker-image,
    null_resource.create_files,
    null_resource.gitlabapi_readiness,
  ]

  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    interpreter = ["bash", "-c"]
    environment = {
      AWS_REGION = var.region,
      AWS_DEFAULT_REGION = var.region
      USERS_COUNT = length(local.users)
    }
    
    command     = <<BASH
    set -e
      sleep 5
      aws codebuild start-build --project-name build-docker-image-${local.users[0].userid} --profile ${var.profile};
      statusCode=1;
      imageDigest="";
      while [[ "$statusCode" != 0 ]] || [[ "$imageDigest" -eq "null" ]]; do 
        echo "Waiting for ECR image to be ready..."; 
        sleep 10; 
        imageDigest=$(aws ecr list-images --repository-name ${local.ecr_repository_name}-${local.users[0].userid} --query 'imageIds[0].imageDigest' --profile ${var.profile} --output text 2>/dev/null);
        statusCode=$?; 
      done

BASH
  }


}


resource "aws_ecr_repository" "app" {
  count = length(local.users)
  name                 = "${local.ecr_repository_name}-${local.users[count.index].userid}"
  image_tag_mutability = "MUTABLE"
}