#Required: AWS Profile
variable "profile" {
}
#Required: AWS Region
variable "region" {
  default = "eu-central-1"
}
#Required: cgID Variable for unique naming
variable "cgid" {
}
#Example: RDS PostgreSQL Instance Credentials
variable "rds-username" {
  default = "sc6admin"
}
variable "rds-password" {
  default = "wagrrrrwwgahhhhwwwrrggawwwwwwrr"
}
variable "rds-database-name" {
  default = "securedb"
}
#SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../SecurityChallenge.pub"
}
variable "ssh-public-key-admin6" {
  default = "../admin6.pub"
}
#Required: User's Public IP Address(es)
variable "cg_whitelist" {
  type = list

}
#Stack Name
variable "stack-name" {
  default = "SecurityChallenge"
}
#Scenario Name
variable "scenario-name" {
  default = "scenario6"
}
#DynamoDB Name
variable "dbName" {
   type        = string
   default     = "users"
   description = "Name for main DB"
 }