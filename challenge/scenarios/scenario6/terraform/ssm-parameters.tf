#AWS SSM Parameters
resource "aws_ssm_parameter" "sc6-ec2-public-key" {
  name = "sc6-ec2-public-key"
  description = "sc6-ec2-public-key"
  type = "String"
  value = file("../SecurityChallenge.pub")
  tags = {
    Name = "sc6-ec2-public-key"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}
resource "aws_ssm_parameter" "sc6-ec2-private-key" {
  name = "sc6-ec2-private-key"
  description = "sc6-ec2-private-key"
  type = "String"
  value = file("../SecurityChallenge")
  tags = {
    Name = "sc6-ec2-private-key"
    Stack = var.stack-name
    Scenario = var.scenario-name
  }
}