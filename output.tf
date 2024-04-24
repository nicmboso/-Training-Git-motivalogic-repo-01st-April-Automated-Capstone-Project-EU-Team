output "wordpress-server" {
  value = aws_instance.EC2-webserver.public_ip
}
output "lb-dns_name" {
  value = aws_lb.alb.dns_name
}