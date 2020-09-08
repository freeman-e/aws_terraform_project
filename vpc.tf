resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.1.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "TerraformLab_Freeman"
  }
}
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
}
data "aws_availability_zones" "azs" {
  state = "available"
}
resource "aws_route" "route" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_subnet" "Public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/25"
}
resource "aws_subnet" "Private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.128/25"
}
resource "aws_security_group" "default" {
  name        = "SSH-allow"
  description = "Allow incoming SSH Connections"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

