 variable "region" {
   default = "eu-central-1"
 }

 variable "dbName" {
   type        = string
   default     = "users"
   description = "Name for main DB"
 }

 variable "profile" {
   type        = string
   default     = "Terraform1"
   description = ""
 }