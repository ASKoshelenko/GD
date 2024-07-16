resource "aws_codebuild_project" "build-docker-image" {
  count = length(local.users)
  name         = "build-docker-image-${local.users[count.index].userid}"
  service_role = aws_iam_role.build-docker-image[count.index].arn

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
      name  = "TOKEN"
      value = "${var.gitlab_token}"
    }
    environment_variable {
      name  = "USER"
      value = "root"
    }
    environment_variable {
      name  = "USERID"
      value = "${local.users[count.index].userid}"
    }
    environment_variable {
      name  = "ADDRESS"
      value = aws_instance.dev.public_ip
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/../assets/buildfromgit/buildspec.yml")
  }
}


resource "aws_iam_role" "build-docker-image" {
  count = length(local.users)
  name = "build-docker-image-role-${local.users[count.index].userid}"

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

resource "aws_iam_role_policy" "build-docker-image" {
  count = length(local.users)
  role = aws_iam_role.build-docker-image[count.index].name

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
      "Effect": "Allow",
      "Resource": [
        "${aws_ecr_repository.app[count.index].arn}"
      ],
      "Action": [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
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
        "${aws_s3_bucket.codepipeline_bucket.arn}/*",
        "${aws_s3_bucket.codepipeline_source_bucket.arn}",
        "${aws_s3_bucket.codepipeline_source_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}