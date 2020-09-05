 resource "aws_vpc" "vpc" {
     cidr_block = "10.0.1.0/24"

     tags = {
      Name = "TerraformLab_Keith"
     }
 }
 resource "aws_internet_gateway" "gateway" {
     vpc_id = aws_vpc.vpc.id
 }
 resource "aws_route" "route" {
     route_table_id         = aws_vpc.vpc.main_route_table_id
     destination_cidr_block = "0.0.0.0/0"
     gateway_id             = aws_internet_gateway.gateway.id
 }
resource "aws_security_group" "default" {
     name        = "SSH-allow"
     description = "Allow incoming SSH Connections"
     vpc_id      = aws_vpc.vpc.id
     ingress {
         from_port = 22
         to_port = 22
         protocol = "tcp"
         cidr_blocks = ["0.0.0.0/0"]
    }
}