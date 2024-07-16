resource "aws_codebuild_project" "deploy-lambda" {
  count = length(local.users)
  name         = "deploy-lambda-function-${local.users[count.index].userid}"
  service_role = aws_iam_role.deploy-lambda[count.index].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = aws_ecr_repository.app[count.index].repository_url
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = module.lambda_function_container_image[count.index].lambda_function_name
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/../assets/cd-pipeline/buildspec.yml")
  }
}


resource "aws_iam_role" "deploy-lambda" {
  count = length(local.users)
  name = "deploy-lambda-role-${local.users[count.index].userid}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "deploy-lambda" {
  count = length(local.users)
  role = aws_iam_role.deploy-lambda[count.index].name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode"
      ],
      "Resource": [
          "${module.lambda_function_container_image[count.index].lambda_function_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "ecr:SetRepositoryPolicy",
          "ecr:GetRepositoryPolicy"
      ],
      "Resource": [
          "${aws_ecr_repository.app[count.index].arn}"
      ]
    }
  ]
}
POLICY
}