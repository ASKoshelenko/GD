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
  type = list

}
# Stack Name
variable "stack-name" {
  default = "EPAM AWS Security Challenge"
}

# Scenario Name
variable "scenario-name" {
  default = "scenario1"
}


 variable "dbName" {
   type        = string
   default     = "users"
   description = "Name for main DB"
 }