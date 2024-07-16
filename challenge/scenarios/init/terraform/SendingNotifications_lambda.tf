# Create lambda_function
resource "aws_lambda_function" "SendingNotifications" {
  filename         = "../assets/SendingNotifications.zip"
  function_name    = "SendingNotifications"
  role             = aws_iam_role.SendingNotifications.arn
  handler          = "SendingNotifications.lambda_handler"
  source_code_hash = filebase64sha256("../assets/SendingNotifications.zip")
  runtime          = "python3.8"
  memory_size      = 256
  timeout          = 900
}

resource "aws_iam_role" "SendingNotifications" {
  name = "SendingNotifications_Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
# Create Inline IAM policy for Cloud Watch
resource "aws_iam_policy" "SendingNotifications_AWSCloudWatchlogs" {
  name   = "SendingNotifications_AWSCloudWatchlogs"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}
# Block policy_attachment
resource "aws_iam_role_policy_attachment" "SendingNotifications_CloudWatch" {
  role       = aws_iam_role.SendingNotifications.name
  policy_arn = aws_iam_policy.SendingNotifications_AWSCloudWatchlogs.arn
}

resource "aws_iam_role_policy_attachment" "SendingNotifications_DynamoDB" {
  role       = aws_iam_role.SendingNotifications.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "SendingNotifications_LambdaBasicExec" {
  role       = aws_iam_role.SendingNotifications.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "SendingNotifications_S3_Access" {
  name   = "SendingNotifications_S3_Access"
  role   = aws_iam_role.SendingNotifications.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "s3:GetAccessPoint",
        "s3:GetLifecycleConfiguration",
        "s3:GetBucketTagging",
        "s3:GetInventoryConfiguration",
        "s3:GetObjectVersionTagging",
        "s3:ListBucketVersions",
        "s3:GetBucketLogging",
        "s3:ListBucket",
        "s3:GetAccelerateConfiguration",
        "s3:GetBucketPolicy",
        "s3:GetObjectVersionTorrent",
        "s3:GetObjectAcl",
        "s3:GetEncryptionConfiguration",
        "s3:GetBucketObjectLockConfiguration",
        "s3:GetBucketRequestPayment",
        "s3:GetAccessPointPolicyStatus",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectTagging",
        "s3:GetMetricsConfiguration",
        "s3:GetBucketOwnershipControls",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketPolicyStatus",
        "s3:ListBucketMultipartUploads",
        "s3:GetObjectRetention",
        "s3:GetBucketWebsite",
        "s3:GetJobTagging",
        "s3:ListAccessPoints",
        "s3:ListJobs",
        "s3:GetBucketVersioning",
        "s3:GetBucketAcl",
        "s3:GetObjectLegalHold",
        "s3:GetBucketNotification",
        "s3:GetReplicationConfiguration",
        "s3:ListMultipartUploadParts",
        "s3:GetObject",
        "s3:GetObjectTorrent",
        "s3:GetAccountPublicAccessBlock",
        "s3:ListAllMyBuckets",
        "s3:DescribeJob",
        "s3:GetBucketCORS",
        "s3:GetAnalyticsConfiguration",
        "s3:GetObjectVersionForReplication",
        "s3:GetBucketLocation",
        "s3:GetAccessPointPolicy",
        "s3:GetObjectVersion"
      ],
      "Resource": "*"
    },
    {
        "Sid": "GetS3ObjectPolicy",
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": [
          "arn:aws:s3:::prepared-user-templates-hackathon",
          "arn:aws:s3:::prepared-user-templates-hackathon/*"
        ]
    }
  ]
}
EOF
}

resource aws_iam_role_policy "SendingNotifications_SSM_Access" {
  name   = "SendingNotifications_SSM_Access"
  role   = aws_iam_role.SendingNotifications.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "ssm:GetParameters",
      "Resource": "arn:aws:ssm:*:*:parameter/*"
    }
  ]
}
EOF
}

# SSM Credentials block

resource "aws_ssm_parameter" "mail" {
  name        = "SMTP-email"
  description = "SMTP email for SendingNotifications lambda function"
  type        = "SecureString"
  value       = var.smtpEmail
  key_id      = "alias/aws/ssm"

  tags = {
    lambda_name = "SendingNotifications"
  }
}

resource "aws_ssm_parameter" "password" {
  name        = "SMTP-password"
  description = "Password for SMTP email"
  type        = "SecureString"
  value       = var.smtpPassword
  key_id      = "alias/aws/ssm"

  tags = {
    lambda_name = "SendingNotifications"
  }
}


