#Required: AWS Profile
variable "profile" {
  default = ""
}
#Required: AWS Region
variable "region" {
  default = "eu-central-1"
}
#Required: CGID Variable for unique naming
variable "cgid" {
}
#Required: User's Public IP Address(es)
 variable "cg_whitelist" {
  type = list

}
#RDS PostgreSQL Instance Credentials
variable "rds-username" {
  default = "sc5admin"
}
variable "rds-password" {
  default = "Purplepwny2029"
}
variable "rds-database-name" {
  default = "securedb"
}

#SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../SecurityChallenge.pub"
}

variable "ssh-public-key-admin5" {
  default = "../admin5.pub"
}
#SSH Private Key
variable "ssh-private-key-for-ec2" {
  default = "../SecurityChallenge"
}
#Stack Name
variable "stack-name" {
  default = "SecurityChallenge"
}
#Scenario Name
variable "scenario-name" {
  default = "scenario5"
}
#DynamoDB Name
variable "dbName" {
   type        = string
   default     = "users"
   description = "Name for main DB"
 }

