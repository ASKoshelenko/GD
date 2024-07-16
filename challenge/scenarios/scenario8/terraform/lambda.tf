module "lambda_function_container_image" {
  count = length(local.users)
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${local.lambda_function_name}-${local.users[count.index].userid}"

  create_package = false

  image_uri    = format("%s:latest", aws_ecr_repository.app[0].repository_url)
  package_type = "Image"

  depends_on = [
    null_resource.create_image,
    ]

}

resource "aws_lambda_permission" "lambda_permission" {
  count = length(local.users)
  statement_id  = "AllowInvokeFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_container_image[count.index].lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_apigatewayv2_api.apigw[count.index].execution_arn}/*/*/*"
}

resource "aws_iam_role_policy" "lambda-image-dynamodb-policy" {
  count = length(local.users)
  name = "lambda-image-dynamodb-policy-${local.users[count.index].userid}"
  role = module.lambda_function_container_image[count.index].lambda_role_name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
		    {
          "Sid": "Terraform1",
          "Effect": "Allow",
          "Action": [
              "dynamodb:PutItem",
              "dynamodb:DeleteItem",
              "dynamodb:GetItem",
              "dynamodb:Scan",
              "dynamodb:Query",
              "dynamodb:UpdateItem",
              "dynamodb:DeleteTable"
            ],
          "Resource": [
              "${aws_dynamodb_table.targetdb[count.index].arn}/index/*",
              "${aws_dynamodb_table.targetdb[count.index].arn}"
            ]
        }
    ]
}
EOF
}