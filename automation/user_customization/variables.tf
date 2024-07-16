#Required: AWS Profile
variable "profile" {
}
#Required: AWS Region
variable "region" {
  default = "eu-central-1"
}
#Required: CGID Variable for unique naming
variable "cgid" {
  default = "123"
}
#Required: User's Public IP Address(es)
 variable "cg_whitelist" {
   type = list
 }
# #RDS PostgreSQL Instance Credentials
# variable "rds-userid" {
#   default = "cgadmin"
# }
# variable "rds-password" {
#   default = "Purplepwny2029"
# }
#SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "./sc7.pub"
}
# #SSH Private Key
# variable "ssh-private-key-for-ec2" {
#   default = "./sc_sc5_2"
# }
#Stack Name
variable "stack-name" {
  default = "SecurityChallenge"
}
#Scenario Name
variable "scenario-name" {
  default = "scenario7"
}
# #DynamoDB Name
# variable "dbName" {
#    type        = string
#    default     = "users"
#    description = "Name for main DB"
#  }