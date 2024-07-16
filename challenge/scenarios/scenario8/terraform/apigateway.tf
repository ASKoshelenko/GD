resource "aws_apigatewayv2_api" "apigw" {
  count = length(local.users)
  name          = "${local.api_gateway_name}-${local.users[count.index].userid}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  count = length(local.users)
  api_id           = aws_apigatewayv2_api.apigw[count.index].id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = module.lambda_function_container_image[count.index].lambda_function_invoke_arn
  payload_format_version = "1.0"
  passthrough_behavior   = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "main_route" {
  count = length(local.users)
  api_id             = aws_apigatewayv2_api.apigw[count.index].id
  route_key          = "POST ${local.api_gateway_route}"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.lambda[count.index].id}"

  request_parameter {
    request_parameter_key = "route.request.header.Authorization"
    required              = false
  }
}

resource "aws_apigatewayv2_deployment" "example" {
  count = length(local.users)
  api_id      = aws_apigatewayv2_route.main_route[count.index].api_id
  description = "Main deployment"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  count = length(local.users)
  api_id        = aws_apigatewayv2_api.apigw[count.index].id
  deployment_id = aws_apigatewayv2_deployment.example[count.index].id
  name          = "prod"
}