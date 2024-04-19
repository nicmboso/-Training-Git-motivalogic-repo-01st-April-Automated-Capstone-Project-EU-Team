
# creating vpc
resource "aws_vpc" "vpc" {
    cidr_block =  var.vpc_cidr
    instance_tenancy = "default"

    tags = {
      Name  = "${local.name}-vpc"
    }
}  

# public subnet1
resource "aws_subnet" "public-subnet1" {
    vpc_id       = aws_vpc.vpc.id
    cidr_block   = var.pubs1_cidr
    availability_zone = var.avz1

    tags = {
      Name = "${local.name}-public-subnet1"
    }
}   

#public subnet2
resource "aws_subnet" "public-subnet2" {
    vpc_id       = aws_vpc.vpc.id
    cidr_block   = var.pubs2_cidr
    availability_zone = var.avz2

    tags =  {
        Name  = "${local.name}-public-subnet2"
    }
}
  
#private subnet1
resource "aws_subnet" "private-subnet1" {
    vpc_id         = aws_vpc.vpc.id
    cidr_block     = var.priv1_cidr
    availability_zone = var.avz1

    tags = {
      Name  = "${local.name}-private-subnet1"
    }
}

#private subnet 2
resource "aws_subnet" "private-subnet2" {
    vpc_id      = aws_vpc.vpc.id
    cidr_block  = var.priv2_cidr
    availability_zone = var.avz2

    tags = {
        Name  = "${local.name}-private-subnet2"
    }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name  = "${local.name}-igw"
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
    subnet_id = aws_subnet.public-subnet1.id
    depends_on = [aws_internet_gateway.igw]

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
    from_port = var.ssh-port
    to_port = var.ssh-port
    protocol = "tcp"
    cidr_blocks = [var.cidr_all]
  } 
  ingress {
    description = "http port"
    from_port = var.http-port
    to_port = var.http-port
    protocol = "tcp"
    cidr_blocks = [var.cidr_all]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
    from_port = var.mysql-port
    to_port = var.mysql-port
    protocol = "tcp"
    cidr_blocks = [var.pubs1_cidr,var.pubs2_cidr]
  } 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.cidr_all]
  } 
  tags = {
    Name = "${local.name}-backend-sg"
  }
}

# dynamic keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits = 4096  
}

resource "local_file" "private_key" {
  content = tls_private_key.keypair.private_key_pem
  filename = "capstone-private-key"
  file_permission = "600"  
}

resource "aws_key_pair" "public_key" {
  key_name = "capstone-public-key"
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
      type = "AWS"
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
  bucket = "capstone-log-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.capstone-log-bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "capstone-media-bucket" {
  bucket = aws_s3_bucket.capstone-media-bucket.id

  target_bucket = aws_s3_bucket.capstone-log-bucket.id
  target_prefix = "log/"
}

# Creating log bucket policy
data "aws_iam_policy_document" "log-bucket-access-policy" {
  statement {
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetObjectVersion"
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


resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "capstone-db-subnet-group"
  subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]

  tags = {
    Name = "${local.name}-DB Subnet Group"
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
    
# Create an AMI from the instance
resource "aws_ami_from_instance" "capstone_ami" {
  name               = "capstone-ami"
  source_instance_id        = aws_instance.capstone_instance.id
  #snapshot_without_reboot = true // Optionally create snapshot without rebooting the instance
}

resource "aws_launch_configuration" "capstone_launch_config" {
  name          = "capstone-launch-config"
  image_id      = "capstone-ami"  
  instance_type = "t2.micro"      
  iam_instance_profile = "capstone-s3-iam" 
  associate_public_ip_address = true
  security_groups = ["capstone-frontend-sg"] 
  key_name = "capstone-key-pair" 
}

resource "aws_autoscaling_group" "capstone_asg" {
  name                 = "capstone-asg"
  launch_configuration = aws_launch_configuration.capstone_launch_config.name
  min_size             = 1
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = ["capstone-pub-sn1", "capstone-pub-sn2"] 
  target_group_arns    = ["arn:aws:elasticloadbalancing:region:account-id:targetgroup/capstone-tg/abcdef1234567890"] 
}

resource "aws_autoscaling_policy" "target_tracking_scale_out" {
  name                   = "capstone-asg-scale-out"
  scaling_adjustment     = null  // Not needed for target tracking policy
  adjustment_type        = null  // Not needed for target tracking policy
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.capstone_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"  
    }
    target_value = 50  
  }
}
