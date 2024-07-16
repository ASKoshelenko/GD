 variable "email" {
   default = [
     "kerrigan@mailboxt.net",
     "abihirna@gmail.com",
     "iryna_abikh@epam.com"
   ]
 }
 
 # Import usernames from emails
 locals {
     # email = [
     # "kerrigan@mailboxt.net",
     # "abihirna@gmail.com",
     # "iryna_abikh@epam.com"
     # ]
     user = [
         for email in var.email: 
         trimsuffix(regex(".*@", email), "@")
     ]
 }

