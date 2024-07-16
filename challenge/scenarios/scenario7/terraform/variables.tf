#Required: AWS Profile
variable "profile" {

}
#Required: AWS Region
variable "region" {
  default = "eu-central-1"
}

#Stack Name
variable "stack-name" {
  default = "EPAM AWS Security Challenge"
}
#Scenario Name
variable "scenario-name" {
  default = "scenario7"
}
 variable "dbName" {
   type        = string
   default     = "users"
   description = "Name for main DB"
 }