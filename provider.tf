provider "aws" {
  region  = var.region
  profile = var.profile
}
locals {
  name   = "capstone"
  emails = ["nicholas.udomboso@cloudhight.com"]
}

