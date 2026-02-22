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

resource "aws_vpc" "shinjuku_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "shinjuku-vpc"
  }
}

# -----------------------------------------
# SUBNETS
# -----------------------------------------

resource "aws_subnet" "shinjuku_public_1" {
  vpc_id                  = aws_vpc.shinjuku_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = { Name = "shinjuku-public-1" }
}

resource "aws_subnet" "shinjuku_public_2" {
  vpc_id                  = aws_vpc.shinjuku_vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = { Name = "shinjuku-public-2" }
}

resource "aws_subnet" "shinjuku_private_1" {
  vpc_id            = aws_vpc.shinjuku_vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "ap-northeast-1a"

  tags = { Name = "shinjuku-private-1" }
}

resource "aws_subnet" "shinjuku_private_2" {
  vpc_id            = aws_vpc.shinjuku_vpc.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = "ap-northeast-1c"

  tags = { Name = "shinjuku-private-2" }
}

# -----------------------------------------
# INTERNET GATEWAY + NAT GATEWAY
# -----------------------------------------

resource "aws_internet_gateway" "shinjuku_igw" {
  vpc_id = aws_vpc.shinjuku_vpc.id
  tags   = { Name = "shinjuku-igw" }
}

resource "aws_eip" "shinjuku_nat_eip" {
  domain = "vpc"
  tags   = { Name = "shinjuku-nat-eip" }
}

resource "aws_nat_gateway" "shinjuku_nat" {
  allocation_id = aws_eip.shinjuku_nat_eip.id
  subnet_id     = aws_subnet.shinjuku_public_1.id
  tags          = { Name = "shinjuku-nat" }

  depends_on = [aws_internet_gateway.shinjuku_igw]
}

# -----------------------------------------
# ROUTE TABLES
# -----------------------------------------

resource "aws_route_table" "shinjuku_public_rt" {
  vpc_id = aws_vpc.shinjuku_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shinjuku_igw.id
  }

  tags = { Name = "shinjuku-public-rt" }
}

resource "aws_route_table" "shinjuku_private_rt" {
  vpc_id = aws_vpc.shinjuku_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.shinjuku_nat.id
  }

  tags = { Name = "shinjuku-private-rt" }
}

resource "aws_route_table_association" "shinjuku_pub1" {
  subnet_id      = aws_subnet.shinjuku_public_1.id
  route_table_id = aws_route_table.shinjuku_public_rt.id
}

resource "aws_route_table_association" "shinjuku_pub2" {
  subnet_id      = aws_subnet.shinjuku_public_2.id
  route_table_id = aws_route_table.shinjuku_public_rt.id
}

resource "aws_route_table_association" "shinjuku_priv1" {
  subnet_id      = aws_subnet.shinjuku_private_1.id
  route_table_id = aws_route_table.shinjuku_private_rt.id
}

resource "aws_route_table_association" "shinjuku_priv2" {
  subnet_id      = aws_subnet.shinjuku_private_2.id
  route_table_id = aws_route_table.shinjuku_private_rt.id
}

# -----------------------------------------
# SECURITY GROUPS
# -----------------------------------------

resource "aws_security_group" "shinjuku_app_sg" {
  name        = "shinjuku-app-sg"
  description = "App tier security group"
  vpc_id      = aws_vpc.shinjuku_vpc.id

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

  tags = { Name = "shinjuku-app-sg" }
}

resource "aws_security_group" "shinjuku_rds_sg" {
  name        = "shinjuku-rds-sg"
  description = "RDS - accepts traffic from app subnets and Sao Paulo only"
  vpc_id      = aws_vpc.shinjuku_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.10.3.0/24", "10.10.4.0/24"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.saopaulo_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "shinjuku-rds-sg" }
}

# -----------------------------------------
# RDS - PHI LIVES HERE AND ONLY HERE
# -----------------------------------------

resource "aws_db_subnet_group" "shinjuku_db_subnet_group" {
  name       = "shinjuku-db-subnet-group"
  subnet_ids = [aws_subnet.shinjuku_private_1.id, aws_subnet.shinjuku_private_2.id]
  tags       = { Name = "shinjuku-db-subnet-group" }
}

resource "aws_db_instance" "shinjuku_rds" {
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.shinjuku_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.shinjuku_rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = { Name = "shinjuku-rds" }
}

# -----------------------------------------
# TRANSIT GATEWAY - TOKYO IS THE HUB
# -----------------------------------------

resource "aws_ec2_transit_gateway" "shinjuku_tgw" {
  description                     = "Tokyo TGW hub"
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = { Name = "shinjuku-tgw" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw.id
  vpc_id             = aws_vpc.shinjuku_vpc.id
  subnet_ids         = [aws_subnet.shinjuku_private_1.id, aws_subnet.shinjuku_private_2.id]

  tags = { Name = "shinjuku-tgw-attachment" }
}

resource "aws_ec2_transit_gateway_peering_attachment" "tokyo_to_saopaulo" {
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgw.id
  peer_transit_gateway_id = var.saopaulo_tgw_id
  peer_region             = "sa-east-1"

  tags = { Name = "shinjuku-to-liberdade-peering" }
}
