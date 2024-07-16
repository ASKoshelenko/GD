#AWS Account Id
data "aws_caller_identity" "aws-account-id" {
  
}
# data "aws_lambda_function" "scenario_4" {
#   function_name = "${var.function_name}"
#   environment {
#       variables = {
#         ScenarioName = "${var.scenario-name}"
#     }
#   } 
# }