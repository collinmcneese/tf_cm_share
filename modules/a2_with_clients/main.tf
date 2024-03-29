# ---------------------------------------------------------------------------------------------------------------------
# module: a2_with_clients

# Places a restraint on using a specific version of terraform
terraform {
  required_version = ">= 0.14"
}

provider "aws" {
  profile = var.aws_profile_name
  region  = var.aws_region
}

################################################################################
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  name_regex  = "^amzn2-ami-hvm-.*x86_64-gp2$"
  owners      = ["amazon"]
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "centos" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["801119661308"]
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = var.vpc_name == "" ? ["Default VPC"] : [var.vpc_name]
  }
}

data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = var.subnet_name == "" ? ["default-${var.aws_region}a"] : [var.subnet_name]
  }
}
