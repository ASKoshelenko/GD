#Required: AWS Profile
variable "profile" {
  default = "CloudGoat"
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
default = ["89.162.139.0/27"]
}
#Stack Name
variable "stack-name" {
  default = "CloudGoat"
}
#Scenario Name
variable "scenario-name" {
  default = "iam-privesc-by-attachment"
}

variable "am-image" {
  default = "ami-0718a1ae90971ce4d"
}