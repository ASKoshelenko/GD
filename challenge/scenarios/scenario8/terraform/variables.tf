variable "repo_readonly_username" {
  default = "sc8_ro_user"
}

variable "repository_name" {
  default = "backend-api"
}

variable "profile" {

}

variable "region" {
  default = "eu-central-1"
}

variable "dbName" {
  type        = string
  default     = "users"
  description = "Name for main DB"
}

variable "targetdb_name" {
  type        = string
  default     = "targetdb"
  description = "Name for DB with secret data"
}

# Scenario Name
variable "scenario-name" {
  default = "scenario8"
}

variable "gitlab_token" {
  default = "glpat-XvnQQL8wpv-AbWSv_Sss"
  description = "EC2 instance type for self hosted GitLab (c5.xlarge - Vendor Recommended)"
}

variable "gitlab_ec2_type" {
  default = "t3.medium"
  description = "EC2 instance type for self hosted GitLab (c5.xlarge - Vendor Recommended)"
}