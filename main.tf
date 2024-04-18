
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
    vpc_id      = aws_vpc.vpc_id
    cidr_block  = var.priv2_cidr
    availability_zone = var.avz2

    tags = {
        Name  = "${local.name}-private-subnet2"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name  = "${local.name}-igw"
    }
}

resource "aws_eip" "eip" {
    depends_on = [ aws_internet_gateway.igw ]
    domain     = "vpc"
}

resource "aws_nat_gateway" "ngw" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.public-subnet1.id
    depends_on = [ aws_internet_gateway.igw ]

    tags = {
      Name = "${local.name}-nat gw"
    }
}
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


# Create bucket for logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "capstone-log-bucket"
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "capstone-media-bucket" {
  bucket = aws_s3_bucket.capstone-media-bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
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
