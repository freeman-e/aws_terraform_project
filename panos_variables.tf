##VARIABLE for pano
variable "access_key" {
    description = "AWS Access Key"
    default = ""
}
variable "secret_key" {
    description = "AWS Secret Key"
    default = ""
}

# AWS Region and Availablility Zone
variable "region" {
    default = "us-east-2"
}

variable "availability_zone" {
    default = "us-east-2b"
}

# VPC configuration
variable "vpc_cidr_block" {
    default = "x.x.x.x/24"
}

variable "vpc_instance_tenancy" {
    default = "default"
}

variable "vpc_name" {
    default = "vpc"
}

# Management subnet configuration
variable "mgmt_subnet_cidr_block" {
    default = "x.x.x.x/24"
}

# Untrust subnet configuration
variable "untrust_subnet_cidr_block" {
    default = "x.x.x.x/24"
}

# Trust subnet configuration
variable "trust_subnet_cidr_block" {
    default = "x.x.x.x/24"
}

# PAVM configuration
variable "pavm_payg_bun2_ami_id" {
//    type = map
    default = {
          us-east-2 = ""ami-0603cbe34fd08cb81"
    }
}

variable "pavm_byol_ami_id" {
//    type = map
    default = {
        us-east-2 = "ami-11e1d774"
    }

}

variable "pavm_instance_type" {
    default = "c4.xlarge"
}

variable "pavm_key_name" {
    description = "Name of the SSH keypair to use in AWS."
    default = "panw-mlue"
}

variable "pavm_key_path" {
    description = "Path to the private portion of the SSH key specified."
    default = "keys/panw-mlue.pem"
}

variable "pavm_public_ip" {
    default = "true"
}

variable "pavm_mgmt_private_ip" {
    default = "x.x.x.x/24"
}

variable "pavm_untrust_private_ip" {
    default = "x.x.x.x/24"
}

variable "pavm_trust_private_ip" {
    default = "x.x.x.x/24""
}

variable pavm_bootstrap_s3 {
    default = "pavm-bootstrap-bucket"
}

# Palo Alto VM-Series Firewall
resource "aws_instance" "pavm" {
    ami = "${lookup(var.pavm_byol_ami_id, var.region)}"
    #ami = "${lookup(var.pavm_payg_bun2_ami_id, var.region)}"
    availability_zone = "${var.availability_zone}"
    tenancy = "default"
    ebs_optimized = false
    disable_api_termination = false
    instance_initiated_shutdown_behavior = "stop"
    instance_type = "${var.pavm_instance_type}"
    key_name = "${var.pavm_key_name}"
    monitoring = false
    vpc_security_group_ids = [ "${aws_security_group.default-security-gp.id}" ]
    subnet_id = "${aws_subnet.mgmt-subnet.id}"
    associate_public_ip_address = "${var.pavm_public_ip}"
    private_ip = "${var.pavm_mgmt_private_ip}"
    source_dest_check = false
    tags = {
        Name = "PAVM"
    }
    root_block_device = {
        volume_type = "gp2"
        volume_size = "65"
        delete_on_termination = true
    }

    connection {
        user = "admin"
        private_key = "${var.pavm_key_path}"
    }
    # bootstrap
    user_data = "vmseries-bootstrap-aws-s3bucket=${var.pavm_bootstrap_s3}"
    iam_instance_profile = "bootstrap_s3_profile"
}

# Untrust Interface
resource "aws_network_interface" "untrust_eni" {
    subnet_id = " ${aws_subnet.untrust-subnet.id}"
    private_ips = [ "${var.pavm_untrust_private_ip}" ]
    security_groups = [ "${aws_security_group.default-security-gp.id}" ]
    description = "PAVM untrust interface"
    source_dest_check = false
    tags = {
        Name = "PAVM_untrust_eni"
    }
    attachment = {
        instance = "${aws_instance.pavm.id}"
        device_index = 1
    }
}

# EIP for Untrust Interface
resource "aws_eip" "untrust_eip" {
    vpc = true
    network_interface = "${aws_network_interface.untrust_eni.id}"
    associate_with_private_ip = "${var.pavm_untrust_private_ip}"
    depends_on = [
        "aws_internet_gateway.pavm-igw"
    ]
}

# Trust Interface
resource "aws_network_interface" "trust_eni" {
    subnet_id = " ${aws_subnet.trust-subnet.id}"
    private_ips = [ "${var.pavm_trust_private_ip}" ]
    security_groups = [ "${aws_security_group.default-security-gp.id}" ]
    description = "PAVM trust interface"
    source_dest_check = false
    tags = {
        Name = "PAVM_trust_eni"
    }
    attachment = {
        instance = "${aws_instance.pavm.id}"
        device_index = 2
    }
}
resource "aws_iam_instance_profile" "bootstrap_s3_profile" {
  name = "bootstrap_s3_profile"
  role = "${aws_iam_role.bootstrap_s3_role.name}"
}

resource "aws_iam_role" "bootstrap_s3_role" {
  name = "bootstrap_s3_role"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource aws_iam_role_policy "bootstrap_s3_role_policy" {
  name = "test_policy"
  role = "${aws_iam_role.bootstrap_s3_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.pavm_bootstrap_s3}",
                "arn:aws:s3:::${var.pavm_bootstrap_s3}/*"
            ]
        }
    ]
}
EOF
}

# Output data
output "general-Instance-ID" {
    value = "${aws_instance.pavm.id}"
}

output "ip-Management-Public-IP" {
    value = "${aws_instance.pavm.public_ip}"
}

output "ip-Management-Private-IP" {
    value = "${aws_instance.pavm.private_ip}"
}

output "ip-Untrust-Public-IP" {
    value = "${aws_eip.untrust_eip.public_ip}"
}

output "ip-Untrust-Private-IP" {
    value = "${aws_eip.untrust_eip.private_ip}"
}

output "ip-Trust-Private-IP" {
    value = "${aws_network_interface.trust_eni.private_ips}"
}



