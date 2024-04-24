# creating vpc
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "${local.name}-vpc"
  }
}

# public subnet1
resource "aws_subnet" "public-subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.pubs1_cidr
  availability_zone = var.avz1

  tags = {
    Name = "${local.name}-public-subnet1"
  }
}

#public subnet2
resource "aws_subnet" "public-subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.pubs2_cidr
  availability_zone = var.avz2

  tags = {
    Name = "${local.name}-public-subnet2"
  }
}

#private subnet1
resource "aws_subnet" "private-subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.priv1_cidr
  availability_zone = var.avz1

  tags = {
    Name = "${local.name}-private-subnet1"
  }
}

#private subnet 2
resource "aws_subnet" "private-subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.priv2_cidr
  availability_zone = var.avz2

  tags = {
    Name = "${local.name}-private-subnet2"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# Elastic ip
resource "aws_eip" "eip" {
  depends_on = [aws_internet_gateway.igw]
  domain     = "vpc"
}

# Nat gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public-subnet1.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${local.name}-nat-gw"
  }
}

#public route table
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.cidr_all
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name}-pub-rt"
  }
}

#private route table
resource "aws_route_table" "priv-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.cidr_all
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "${local.name}-priv-rt"
  }
}

#Route table associations
resource "aws_route_table_association" "rta-pub1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "rta-pub2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "rta-priv1" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.priv-rt.id
}

resource "aws_route_table_association" "rta-priv2" {
  subnet_id      = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.priv-rt.id
}

#Creating security group
resource "aws_security_group" "frontend-sg" {
  name        = "frontend-sg"
  description = "frontend security group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "ssh port"
    from_port   = var.ssh-port
    to_port     = var.ssh-port
    protocol    = "tcp"
    cidr_blocks = [var.cidr_all]
  }
  ingress {
    description = "http port"
    from_port   = var.http-port
    to_port     = var.http-port
    protocol    = "tcp"
    cidr_blocks = [var.cidr_all]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_all]
  }
  tags = {
    Name = "${local.name}-frontend-sg"
  }
}

resource "aws_security_group" "backend-sg" {
  name        = "backend-sg"
  description = "backend security group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "mysql port"
    from_port   = var.mysql-port
    to_port     = var.mysql-port
    protocol    = "tcp"
    cidr_blocks = [var.pubs1_cidr, var.pubs2_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_all]
  }
  tags = {
    Name = "${local.name}-backend-sg"
  }
}

# dynamic keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "capstone-private-key"
  file_permission = "600"
}

resource "aws_key_pair" "public_key" {
  key_name   = "capstone-public-key"
  public_key = tls_private_key.keypair.public_key_openssh
}

# Creating media bucket
resource "aws_s3_bucket" "capstone-media-bucket" {
  bucket        = "capstone-media-bucket"
  force_destroy = true
  tags = {
    Name = "${local.name}-media-bucket"
  }
}

data "aws_iam_policy_document" "media-bucket-access-policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetObjectVersion"
    ]
    resources = [
      aws_s3_bucket.capstone-media-bucket.arn,
      "${aws_s3_bucket.capstone-media-bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "capstone-media-bucket-policy" {
  bucket = aws_s3_bucket.capstone-media-bucket.id
  policy = data.aws_iam_policy_document.media-bucket-access-policy.json
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
    Name = "${local.name}-code-bucket"
  }
}


# Create bucket for logging
resource "aws_s3_bucket" "capstone-log-bucket" {
  bucket        = "capstone-log-bucket"
  force_destroy = true
  tags = {
    Name = "${local.name}-log-bucket"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_owner]
  bucket     = aws_s3_bucket.capstone-log-bucket.id
  acl        = "private"
}
resource "aws_s3_bucket_ownership_controls" "log_bucket_owner" {
  bucket = aws_s3_bucket.capstone-log-bucket.id 
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
# resource "aws_s3_bucket_logging" "capstone-media-bucket" {
#   bucket = aws_s3_bucket.capstone-media-bucket.id

#   target_bucket = aws_s3_bucket.capstone-log-bucket.id
#   target_prefix = "log/"
# }

# Creating log bucket policy
data "aws_iam_policy_document" "log-bucket-access-policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:GetBucketAcl",
      "s3:PutBucketAcl",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.capstone-log-bucket.arn,
      "${aws_s3_bucket.capstone-log-bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "capstone-log-bucket-policy" {
  bucket = aws_s3_bucket.capstone-log-bucket.id
  policy = data.aws_iam_policy_document.log-bucket-access-policy.json
}
resource "aws_s3_bucket_public_access_block" "log_bucket_access_block" {
  bucket = aws_s3_bucket.capstone-log-bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}


#Create IAM role 
resource "aws_iam_role" "iam_role" {
  name = "${local.name}-iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    tag-key = "iam_role"
  }
}

#Create media-bucket IAM policy 
resource "aws_iam_policy" "s3-policy" {
  name = "${local.name}-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*"]
        Resource = "*"
        Effect   = "Allow"
      },
    ]
  })
}

#Attaching IAM_role_policy to s3 media-bucket policy
resource "aws_iam_role_policy_attachment" "iam-role-attached-mediabucket" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.s3-policy.arn
}

resource "aws_iam_instance_profile" "iam-instance-profile" {
  name = "${local.name}-instance-profile"
  role = aws_iam_role.iam_role.name
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "capstone-db-subnet-group"
  subnet_ids = [aws_subnet.private-subnet1.id, aws_subnet.private-subnet2.id]

  tags = {
    Name = "${local.name}-db-sg"
  }
}
resource "aws_db_instance" "databasewp" {
  identifier             = var.db-identifier
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.backend-sg.id]
  allocated_storage      = 10
  db_name                = var.db-name
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = var.db-username
  password               = var.db-password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  publicly_accessible    = false
  storage_type           = "gp2"
}
resource "aws_instance" "EC2-webserver" {
  ami                         = var.red-hat
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.public-subnet1.id
  vpc_security_group_ids      = [aws_security_group.frontend-sg.id, aws_security_group.backend-sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.iam-instance-profile.id
  key_name                    = aws_key_pair.public_key.key_name
  tags = {
    Name = "${local.name}-webserver"
  }
}

# Creating Load Balancer Target Group
resource "aws_lb_target_group" "lb-tg" {
  name_prefix = "lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

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
  target_id        = aws_instance.EC2-webserver.id
  port             = 80
}

# Creating Application Load Balancer
resource "aws_lb" "alb" {
  name                       = "capstone-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.frontend-sg.id]
  subnets                    = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.capstone-log-bucket.id
    prefix  = "lb-logs"
    enabled = true
  }
  tags = {
    Name = "${local.name}-alb"
  }
}

# Creating Load Balancer Listener for http
resource "aws_lb_listener" "capstone_lb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg.arn
  }
}
# Route 53 hosted zone
data "aws_route53_zone" "caprt_zone" {
  name         = "unstoppablefunmie.com"
  private_zone = false
}
# Adding ELB to route 53 domain 
resource "aws_route53_record" "elb_dns_record" {
  zone_id = data.aws_route53_zone.caprt_zone.zone_id
  name    = "unstoppablefunmie.com"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}

# Create an AMI from the instance
resource "aws_ami_from_instance" "capstone-ami" {
  name                    = "capstone-ami"
  source_instance_id      = aws_instance.EC2-webserver.id
  snapshot_without_reboot = true
  depends_on              = [aws_instance.EC2-webserver, time_sleep.server-wait-time]
}
resource "time_sleep" "server-wait-time" {
  depends_on      = [aws_instance.EC2-webserver]
  create_duration = "420s"
}
resource "aws_launch_configuration" "capstone_launch_config" {
  name                        = "capstone-launch-config"
  image_id                    = "capstone-ami"
  instance_type               = var.instance-type
  iam_instance_profile        = aws_iam_instance_profile.iam-instance-profile.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.frontend-sg.id]
  key_name                    = aws_key_pair.public_key.id
}

resource "aws_autoscaling_group" "capstone_asg" {
  name                 = "capstone-asg"
  launch_configuration = aws_launch_configuration.capstone_launch_config.name
  min_size             = 1
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  target_group_arns    = ["${aws_lb_target_group.lb-tg.arn}"]
  tag {
    key                 = "Name"
    value               = "ASG"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "ASG-policy" {
  name                   = "ASG-policy"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.capstone_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

resource "aws_cloudwatch_dashboard" "asg_dashboard" {
  dashboard_name = "ASG_Dashboard"

  dashboard_body = jsonencode({
    widgets : [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "capstone-asg", { "label" : "Average CPU Utilization" }]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          region  = "eu-west-3"
          title   = "avarage CPU utilization"
          yAxis = {
            left = {
              label     = "percentage"
              showUnits = true
            }
          }
        }
      }
    ]
  })
}
resource "aws_cloudwatch_metric_alarm" "asg_cpu_utilization_alarm" {
  alarm_name          = "ASG_CPU_Utilization_Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "This alarm will trigger if CPU utilization is greater than or equal to 50% for 2 consecutive periods."
  alarm_actions       = [aws_autoscaling_policy.ASG-policy.arn, aws_sns_topic.user_updates.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.capstone_asg.name
  }
}
# Create Cloudfront distribution
locals {
  s3_origin_id = aws_s3_bucket.capstone-media-bucket.id
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.capstone-media-bucket.bucket_domain_name
    origin_id   = local.s3_origin_id
  }
  enabled = true

  logging_config {
    include_cookies = false
    bucket          = "capstone-log-bucket.s3.amazon.com"
    prefix          = "cloudfront-logs"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
data "aws_cloudfront_distribution" "cloudfront" {
  id = aws_cloudfront_distribution.s3_distribution.id
}
#create sns topic
resource "aws_sns_topic" "user_updates" {
  name            = "user-updates-topic"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}
# sns topic subcription
resource "aws_sns_topic_subscription" "user_updates_email_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  count     = length(local.emails)
  protocol  = "email"
  endpoint  = local.emails[count.index]
}