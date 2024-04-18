provider "aws" {
  region = "eu-west-3"
}

resource "aws_s3_bucket" "capstone-media-bucket" {
  bucket        = "capstone-media-bucket"
  force_destroy = true
  tags = {
    Name = "capstone-media-bucket"
  }
}
resource "aws_s3_bucket_policy" "capstone-media-bucket-policy" {
  bucket = aws_s3_bucket.capstone-media-bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.capstone-media-bucket.arn}/*"
        ]
      }
    ]
  })
}
resource "aws_s3_bucket_public_access_block" "media_bucket_access_block" {
  bucket = aws_s3_bucket.capstone-media-bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket" "capstone-code-bucket" {
  bucket        = "capstone-code-bucket"
  force_destroy = true
  tags = {
    Name = "capstone-code-bucket"
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "capstone-db-subnet-group"
  subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]

  tags = {
    Name = "Capstone DB Subnet Group"
  }
}


resource "aws_db_instance" "databasewp" {
  identifier             = var.identifier
  db_subnet_group_name   = aws_db_subnet_group.capstone_database
  vpc_security_group_ids = [aws_security_group.backend.id]
  allocated_storage      = 10
  db_name                = capstone_database    
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "admin123"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  publicly_accessible    = false
  storage_type           = "gp2"
}


# Creating Load Balancer Target Group
resource "aws_lb_target_group" "lb-tg" {
  name_prefix = "capstone_lb-tg"  
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-id-placeholder"  

  health_check {
    interval            = 60
    path                = "/indextest.html"
    port                = 80
    protocol            = "HTTP"
    timeout             = 30
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

# Creating Load Balancer Target Group Attachment
resource "aws_lb_target_group_attachment" "tg_att" {
  target_group_arn = aws_lb_target_group.lb-tg.arn  
  target_id        = "instance-id-placeholder"
  port             = 80
}

# Creating Application Load Balancer
resource "aws_lb" "alb" {
  name                       = "capstone-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["security-group-placeholder"]
  subnets                    = ["subnet-placeholder-1", "subnet-placeholder-2"]
  enable_deletion_protection = false

  access_logs {
    bucket  = "s3-bucket-placeholder"
    prefix  = "lb-logs"
    enabled = true
  }
    tags = {
      Name = "${capstone.lb}-alb"
  }
}

# Creating Load Balancer Listener for http
resource "aws_lb_listener" "capstone_lb_listener" {
  load_balancer_arn = aws_lb_alb.arn   
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg.arn   
  }
}

# Adding ELB to route 53 domain 
resource "aws_route53_record" "elb_dns_record" {
  zone_id = "zone_id_placeholder"  
  name    = "placeholder.com"              
  type    = "A"

  alias {
    name                   = "alb_dns_name_placeholder"  
    zone_id                = "alb_zone_id_placeholder"  
    evaluate_target_health = false
  }
}
