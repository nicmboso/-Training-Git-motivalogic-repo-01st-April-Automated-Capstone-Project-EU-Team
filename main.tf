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
  protocol  = "email"
  endpoint  = email@example.com
}
