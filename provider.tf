provider "aws" {
  region = var.region
  profile = var.profile
}
locals {
  name = "capstone"
}

