provider "aws" {
    region =  var.region
    profile = var.profile
}
locals {
  Name = "capstone"
}
provider "aws" {
  alias  = "sns"
  region = var.sns["eu-west-3"] } 