terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------
# VPC
# -----------------------------------------

resource "aws_vpc" "liberdade_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "liberdade-vpc" }
}

# -----------------------------------------
# SUBNETS
# -----------------------------------------

resource "aws_subnet" "liberdade_public_1" {
  vpc_id                  = aws_vpc.liberdade_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "sa-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "liberdade-public-1" }
}

resource "aws_subnet" "liberdade_public_2" {
  vpc_id                  = aws_vpc.liberdade_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "sa-east-1c"
  map_public_ip_on_launch = true

  tags = { Name = "liberdade-public-2" }
}

resource "aws_subnet" "liberdade_private_1" {
  vpc_id            = aws_vpc.liberdade_vpc.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = "sa-east-1a"

  tags = { Name = "liberdade-private-1" }
}

resource "aws_subnet" "liberdade_private_2" {
  vpc_id            = aws_vpc.liberdade_vpc.id
  cidr_block        = "10.20.4.0/24"
  availability_zone = "sa-east-1c"

  tags = { Name = "liberdade-private-2" }
}

# -----------------------------------------
# INTERNET GATEWAY + NAT
# -----------------------------------------

resource "aws_internet_gateway" "liberdade_igw" {
  vpc_id = aws_vpc.liberdade_vpc.id
  tags   = { Name = "liberdade-igw" }
}

resource "aws_eip" "liberdade_nat_eip" {
  domain = "vpc"
  tags   = { Name = "liberdade-nat-eip" }
}

resource "aws_nat_gateway" "liberdade_nat" {
  allocation_id = aws_eip.liberdade_nat_eip.id
  subnet_id     = aws_subnet.liberdade_public_1.id
  tags          = { Name = "liberdade-nat" }
  depends_on    = [aws_internet_gateway.liberdade_igw]
}

# -----------------------------------------
# ROUTE TABLES
# -----------------------------------------

resource "aws_route_table" "liberdade_public_rt" {
  vpc_id = aws_vpc.liberdade_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.liberdade_igw.id
  }

  route {
    cidr_block         = var.tokyo_cidr
    transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw.id
  }

  tags = { Name = "liberdade-public-rt" }
}

resource "aws_route_table" "liberdade_private_rt" {
  vpc_id = aws_vpc.liberdade_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.liberdade_nat.id
  }

  route {
    cidr_block         = var.tokyo_cidr
    transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw.id
  }

  tags = { Name = "liberdade-private-rt" }
}

resource "aws_route_table_association" "liberdade_pub1" {
  subnet_id      = aws_subnet.liberdade_public_1.id
  route_table_id = aws_route_table.liberdade_public_rt.id
}

resource "aws_route_table_association" "liberdade_pub2" {
  subnet_id      = aws_subnet.liberdade_public_2.id
  route_table_id = aws_route_table.liberdade_public_rt.id
}

resource "aws_route_table_association" "liberdade_priv1" {
  subnet_id      = aws_subnet.liberdade_private_1.id
  route_table_id = aws_route_table.liberdade_private_rt.id
}

resource "aws_route_table_association" "liberdade_priv2" {
  subnet_id      = aws_subnet.liberdade_private_2.id
  route_table_id = aws_route_table.liberdade_private_rt.id
}

# -----------------------------------------
# SECURITY GROUP
# -----------------------------------------

resource "aws_security_group" "liberdade_app_sg" {
  name        = "liberdade-app-sg"
  description = "App tier - stateless compute only"
  vpc_id      = aws_vpc.liberdade_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "liberdade-app-sg" }
}

# -----------------------------------------
# EC2 + AUTO SCALING GROUP
# -----------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "liberdade_lt" {
  name_prefix   = "liberdade-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "DB_HOST=${data.terraform_remote_state.tokyo.outputs.tokyo_rds_endpoint}" >> /etc/environment
    yum install -y mysql
    EOF
  )

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.liberdade_app_sg.id]
  }

  tags = { Name = "liberdade-lt" }
}

resource "aws_autoscaling_group" "liberdade_asg" {
  name                = "liberdade-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = [aws_subnet.liberdade_private_1.id, aws_subnet.liberdade_private_2.id]

  launch_template {
    id      = aws_launch_template.liberdade_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "liberdade-ec2"
    propagate_at_launch = true
  }
}

# -----------------------------------------
# TRANSIT GATEWAY - SAO PAULO IS THE SPOKE
# -----------------------------------------

resource "aws_ec2_transit_gateway" "liberdade_tgw" {
  description                     = "Sao Paulo TGW spoke - routes all DB traffic to Tokyo"
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = { Name = "liberdade-tgw" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw.id
  vpc_id             = aws_vpc.liberdade_vpc.id
  subnet_ids         = [aws_subnet.liberdade_private_1.id, aws_subnet.liberdade_private_2.id]

  tags = { Name = "liberdade-tgw-attachment" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accept_tokyo_peering" {
  transit_gateway_attachment_id = data.terraform_remote_state.tokyo.outputs.tokyo_tgw_peering_attachment_id

  tags = { Name = "liberdade-accepts-shinjuku-peering" }
}
