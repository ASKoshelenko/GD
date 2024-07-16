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
 variable "scenarios"{
   type = list
   default = [
    "scenario1",
    "scenario2",
    "scenario3",
    "scenario4",
    "scenario5",
    "scenario6",
    "scenario7",
    "scenario8"
   ]
 }
 variable "result_bucket_name" {
   type = string
   default = "result-game-day"
 }
 variable "smtpEmail" {
   type = string 
   default = "Auto_EPMC-ACM_AWS_Game_Day@epam.com"
 }

 variable "smtpPassword" {
   type = string
 }