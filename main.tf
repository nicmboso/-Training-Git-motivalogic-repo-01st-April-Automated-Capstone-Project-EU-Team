resource "aws_s3_bucket" "capstone-media-bucket" {
  bucket        = "capstone-media-bucket"
  force_destroy = true
  tags = {
    Name = "${local.name}-media-bucket"
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
          "arn:aws:s3:::capstone-media-bucket.arn/*"
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
    Name = "${local.name}-code-bucket"
  }
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
