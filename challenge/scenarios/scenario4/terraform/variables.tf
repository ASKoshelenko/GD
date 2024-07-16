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
#SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../securitychallenge.pub"
}
variable "ssh-public-key-admin4" {
  default = "../admin4.pub"
}
#SSH Private Key
variable "ssh-private-key-for-ec2" {
  default = "../securitychallenge"
}
#Stack Name
variable "stack-name" {
  default = "SecurityChallenge"
}
#Scenario Name
variable "scenario-name" {
  default = "scenario4"
}
#Valid AMI
variable "ami" {
  default = "ami-0718a1ae90971ce4d"  
}

#DynamoDB Name
variable "dbName" {
   default     = "users"
   description = "Name for main DB"
 }
#Required: User's Public IP Address(es)
variable "cg_whitelist" {
   type = list
     default = [""]
 }