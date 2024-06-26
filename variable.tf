variable "region" {
  default = "eu-west-3"
}
variable "profile" {
  default = "set19"
}
variable "red-hat" {
  default = "ami-05f804247228852a3"
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
variable "ssh-port" {
  default = "22"
}
variable "http-port" {
  default = "80"
}
variable "mysql-port" {
  default = "3306"
}
variable "db-identifier" {
  default = "wordpressdb"
}
variable "db-name" {
  default = "capstonedb"
}
variable "db-username" {
  default = "admin"
}
variable "db-password" {
  default = "admin123"
}
variable "instance-type" {
  default = "t2.medium"
}
  