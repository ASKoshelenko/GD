# Create lambda_function
resource "aws_lambda_function" "SendInitData" {
  filename         = "SendInitData.zip"
  function_name    = "SendInitData"
  role             = aws_iam_role.SNSAccessForLamdaRole.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("SendInitData.zip")
  runtime          = "python3.8"
}
#CloudWatch event rule and target for Lambda
resource "aws_cloudwatch_event_rule" "SendInitData" {
  name                = "SendInitData"
  schedule_expression = "rate(1 hour)"
}
resource "aws_cloudwatch_event_target" "SendInitData" {
  rule      = aws_cloudwatch_event_rule.SendInitData.name
  target_id = "SendInitData"
  arn       = aws_lambda_function.SendInitData.arn
}

#lambda permission
resource "aws_lambda_permission" "SendInitData" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SendInitData.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.SendInitData.arn
}