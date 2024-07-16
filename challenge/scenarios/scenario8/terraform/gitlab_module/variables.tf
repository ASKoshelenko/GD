variable "gitlab_token" {
  description = "GitLab token for ec2 instance"
  type = string
}

variable "public_ip" {
  description = "GitLab ec2 public ip"
}

variable "userid" {
  description = "Users id"
}

variable "keys" {
  description = "Users ssh keys"
}


variable "scenario-name" {
  description = "scenario name"
  type = string
}

variable "repo_readonly_username" {
  description = "Readonly username"
  type = string
}

variable "gitlab_hook" {
  description = "GitLabhook url"
  type = string
}
