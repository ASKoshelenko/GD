locals {
  # Ensure the bucket suffix doesn't contain invalid characters
  # "Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-)."
  # (per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) 
  bucket_suffix = "sc8"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "codepipeline-bucket-${local.bucket_suffix}"
  acl           = "private" 
  force_destroy = true
}

resource "aws_s3_bucket" "codepipeline_source_bucket" {
  bucket        = "codepipeline-source-bucket-${local.bucket_suffix}"
  acl           = "private" 
  force_destroy = true
  versioning {
    enabled = true
  }

}

resource "aws_s3_object" "file_upload" {
  bucket = aws_s3_bucket.codepipeline_source_bucket.id
  key    = "SimpleApp.zip"
  source = "${path.module}/../assets/buildfromgit/SimpleApp.zip"
}


resource "aws_iam_role" "codepipeline" {
  count = length(local.users)
  name = "codepipeline-role-${local.users[count.index].userid}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline" {
  count = length(local.users)
  role = aws_iam_role.codepipeline[count.index].name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
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
      "Resource": [
        "${aws_codebuild_project.build-docker-image[count.index].arn}",
        "${aws_codebuild_project.deploy-lambda[count.index].arn}",
        "${aws_codebuild_project.acceptance-test[count.index].arn}"
      ] 
    }
  ]
}
POLICY
}

resource "aws_codepipeline" "codepipeline" {
  count = length(local.users)
  name     = "${local.codepipeline_name}-${local.users[count.index].userid}"
  role_arn = aws_iam_role.codepipeline[count.index].arn
/*
  depends_on = [
    null_resource.upload_files,
  ] */
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket = aws_s3_bucket.codepipeline_source_bucket.id
        S3ObjectKey = "SimpleApp.zip"
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build-docker-image[count.index].name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy-lambda[count.index].name
      }
    }
  }

  stage {
    name = "Acceptance"

    action {
      name            = "Acceptance"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.acceptance-test[count.index].name
      }
    }
  }

}