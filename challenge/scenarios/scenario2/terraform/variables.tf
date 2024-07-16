# Required: AWS Profile
variable "profile" {

}
# Required: AWS Region
variable "region" {
  default = "eu-central-1"
}
# Required: CGID Variable for unique naming
variable "cgid" {

}
# Required: User's Public IP Address(es)
variable "cg_whitelist" {
  default = "../whitelist.txt"
}
# SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../challenge.pub"
}
# SSH Private Key
variable "ssh-private-key-for-ec2" {
  default = "../challenge"
}
# Stack Name
variable "stack-name" {
  default = "SecurityChallenge"
}
# Scenario Name
variable "scenario-name" {
  default = "scenario2"
}
variable "am-image" {
  default = "ami-0718a1ae90971ce4d"
}

variable "dbName" {
  type        = string
  default     = "users"
  description = "Name for main DB"
}