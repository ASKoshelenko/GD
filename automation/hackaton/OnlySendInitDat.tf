resource "aws_lambda_function" "OnlySendInitData" {
  filename         = "../lambda/SendInitData.zip"
  function_name    = "SendInitData"
  role             = aws_iam_role.SNSAccessForLamdaRole.arn
  handler          = "SendInitData.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/SendInitData.zip")
  runtime          = "python3.8"
  environment {
    variables = {
      ScenarioName = "scenario1"
    }
  }
}
#CloudWatch event rule and target for Lambda
resource "aws_cloudwatch_event_rule" "OnlySendInitData" {
  name                = "OnlySendInitData"
  schedule_expression = "rate(5 minutes)"
}
resource "aws_cloudwatch_event_target" "OnlySendInitData" {
  rule      = aws_cloudwatch_event_rule.OnlySendInitData.name
  target_id = "OnlySendInitData"
  arn       = aws_lambda_function.OnlySendInitData.arn
}

#lambda permission
resource "aws_lambda_permission" "OnlySendInitData" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.OnlySendInitData.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.OnlySendInitData.arn
}