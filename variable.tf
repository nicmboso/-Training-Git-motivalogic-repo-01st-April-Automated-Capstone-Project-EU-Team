variable "region" {
  default = "eu-west-3"
}
variable "profile" {
    default = "set19"
}
variable "red-hat" {
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "pubs1_cidr" {
  default = "10.0.1.0/24"
}
variable "pubs2_cidr" {
  default = "10.0.2.0/24"
}
variable "avz1" {
  default = "eu-west-3a"
}
variable "avz2" {
  default = "eu-west-3b"
}
variable "priv1_cidr" {
  default = "10.0.3.0/24"
}
variable "priv2_cidr" {
  default = "10.0.4.0/24"
}
variable "cidr_all" {
  default = "0.0.0.0/0"
}
variable "ssh-port"{
  default = "22"
}
variable "http-port"{
  default = "80"
}
variable "mysql-port"{
  default = "3306"
}

