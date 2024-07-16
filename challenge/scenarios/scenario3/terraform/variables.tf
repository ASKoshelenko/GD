#Required: AWS Profile
variable "profile" {
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
#Stack Name
variable "stack-name" {
  default = "SecurityChallenge"
}
#Scenario Name
variable "scenario-name" {
  default = "scenario3"
}

variable "am-image" {
  default = "ami-0718a1ae90971ce4d"
}

variable "dbName" {
  type        = string
  default     = "users"
  description = "Name for main DB"
}