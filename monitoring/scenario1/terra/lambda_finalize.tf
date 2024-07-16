resource "aws_iam_policy" "fin_lambda_policy" {
  name = "CGSc1FinCheck-policy"
  path = "/"
  description = "IAM policy for reading dynamoDB"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "dynamodb:Scan",
            "Resource": "*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "cloudtrail:LookupEvents",
            "Resource": "*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "sns:Publish",
            "Resource": "*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "dynamodb:UpdateItem",
            "Resource": "*"
        },
		    {
		    "Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
		    ],
		    "Effect": "Allow",
		    "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "CGSc1FinCheck-role"
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

resource "aws_iam_role_policy_attachment" "CGSC1FinCheck_attachment" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.fin_lambda_policy.arn
}

resource "aws_lambda_function" "CGSC1FinCheck_lambda" {
  filename      = "CGFinCheck.zip"
  function_name = "CGSC1FinCheck"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "CGFinCheck.lambda_handler"
  source_code_hash = filebase64sha256("CGFinCheck.zip")

  runtime = "python3.8"

}

resource "aws_cloudwatch_event_rule" "aws_cli_iam_events" {
  name        = "capture-aws-cli-iam-events"
  schedule_expression = "cron(0 5-20/1 ? * MON-FRI *)" 
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.CGSC1FinCheck_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aws_cli_iam_events.arn
}

resource "aws_cloudwatch_event_target" "aws_cli_iam_trigger" {
    rule = aws_cloudwatch_event_rule.aws_cli_iam_events.name
    target_id = "aws_cli_iam_trigger"
    arn = aws_lambda_function.CGSC1FinCheck_lambda.arn
}
