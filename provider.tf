provider "aws" {
  region  = var.region
  profile = var.profile
}
locals {
  name   = "capstone"
  emails = ["alangallagher219@gmail.com", "Akintoyelayo@gmail.com", "nora.kehinde@cloudhight.com", "nicholas.udomboso@cloudhight.com", "sammy.utere@cloudhight.com"]
}

