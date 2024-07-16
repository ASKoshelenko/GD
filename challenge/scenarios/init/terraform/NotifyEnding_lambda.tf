# Create lambda_function
resource "aws_lambda_function" "NotifyScenarioEnding" {
  filename         = "../lambda/NotifyScenarioEnding.zip"
  function_name    = "NotifyScenarioEnding"
  role             = aws_iam_role.SendInitData.arn
  handler          = "NotifyScenarioEnding.lambda_handler"
  source_code_hash = filebase64sha256("../lambda/NotifyScenarioEnding.zip")
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      ScenarioName = "scenario1"
    }
  }
}
#CloudWatch event rule and target for Lambda
resource "aws_cloudwatch_event_rule" "NotifyScenarioEnding" {
  name                = "NotifyScenarioEnding"
  schedule_expression = "rate(24 hours)"
}
resource "aws_cloudwatch_event_target" "NotifyScenarioEnding" {
  rule      = aws_cloudwatch_event_rule.NotifyScenarioEnding.name
  target_id = "NotifyScenarioEnding"
  arn       = aws_lambda_function.NotifyScenarioEnding.arn
}

#lambda permission
resource "aws_lambda_permission" "NotifyScenarioEnding" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.NotifyScenarioEnding.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.NotifyScenarioEnding.arn
}
