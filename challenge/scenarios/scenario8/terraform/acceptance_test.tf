/*
# Scheduling
resource "aws_iam_role" "acceptance-test-scheduling" {
  count = length(local.users)
  name = "acceptance-test-scheduling-role-${local.users[count.index].userid}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "acceptance-test-scheduling" {
  count = length(local.users)
  role = aws_iam_role.acceptance-test-scheduling[count.index].name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:StartBuild"
      ],
      "Resource": "${aws_codebuild_project.acceptance-test[count.index].arn}"
    }
  ]
}
POLICY
}

resource "aws_cloudwatch_event_rule" "schedule" {
  count = length(local.users)
  name                = "simulated-user-activity-${local.users[count.index].userid}"
  description         = "Simulate user activity on the API"
  schedule_expression = "rate(600 minutes)"
}
resource "aws_cloudwatch_event_target" "codebuild" {
  count = length(local.users)
  target_id = "trigger-codebuild-${local.users[count.index].userid}"
  rule      = aws_cloudwatch_event_rule.schedule[count.index].id
  arn       = aws_codebuild_project.acceptance-test[count.index].arn
  role_arn  = aws_iam_role.acceptance-test-scheduling[count.index].arn
}

*/
# Codebuild
resource "aws_codebuild_project" "acceptance-test" {
  count = length(local.users)
  name         = "OUTOFSCOPE_acceptance-test-${local.users[count.index].userid}"
  service_role = aws_iam_role.acceptance-test[count.index].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    privileged_mode = true
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name = "SECRET_FLAG"
      # Note: This is a base64 version of the secret flag
      # It shouldn't be accessible in the live environment because the step3 user has an
      # explicit deny on this CloudBuild project
      value = "RkxBR3tTdXBwbHlDaDQhblMzY3VyaXR5TTR0dDNyNSJ9"
    }

    environment_variable {
      name  = "API_URL"
      value = aws_apigatewayv2_stage.prod[count.index].invoke_url
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/../assets/simulated-user-activity/buildspec.yml")
  }
}


resource "aws_iam_role" "acceptance-test" {
  count = length(local.users)
  name = "acceptance-test-role-${local.users[count.index].userid}"

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
resource "aws_iam_role_policy" "acceptance-test" {
  count = length(local.users)
  role = aws_iam_role.acceptance-test[count.index].name

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
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
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