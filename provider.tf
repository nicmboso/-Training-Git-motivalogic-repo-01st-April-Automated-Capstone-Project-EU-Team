provider "aws" {
    region =  var.region
    profile = var.profile
}
locals {
  Name = "capstone"
}