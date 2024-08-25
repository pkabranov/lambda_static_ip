# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hashicorp-learn = "lambda-api-gateway"
    }
  }

}

# Define VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_block
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-public-subnet"
  }
}

# Private subnet 1 (Availability Zone 1)
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_1_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = "us-west-1a"
  tags = {
    Name = "${var.project}-private-subnet-1"
  }
}

# Private subnet 2 (Availability Zone 2)
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_2_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = "us-west-1c"
  tags = {
    Name = "${var.project}-private-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-internet-gateway"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "eip_nat_gateway" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip_nat_gateway.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.project}-nat-gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gateway]
}

# Public Subnet 1 Route Table (sends traffic to internet gateway)
resource "aws_route_table" "public_subnet_1_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.project}-public-subnet-1-route-table"
  }
}

# Public Subnet 1 Route Table Association
resource "aws_route_table_association" "public_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_subnet_1_route_table.id
}

# Private Subnet 1 Route Table 
resource "aws_route_table" "private_subnet_1_route_table" {
  vpc_id = aws_vpc.vpc.id

  # Define default route inline
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.project}-private-subnet-1-route-table"
  }
}

# Private Subnet 1 Route Table Association
resource "aws_route_table_association" "private_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_subnet_1_route_table.id
}

# Private Subnet 2 Route Table 
resource "aws_route_table" "private_subnet_2_route_table" {
  vpc_id = aws_vpc.vpc.id

  # Define default route inline
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.project}-private-subnet-2-route-table"
  }
}

# Private Subnet 2 Route Table Association
resource "aws_route_table_association" "private_subnet_2_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_subnet_2_route_table.id
}
