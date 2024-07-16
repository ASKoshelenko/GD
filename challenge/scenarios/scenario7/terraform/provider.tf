provider "aws" {
  profile = var.profile
  region  = var.region
}
terraform {
  backend "s3" {
    key = "scenario/sc7/terraform.tfstate"
  }
}