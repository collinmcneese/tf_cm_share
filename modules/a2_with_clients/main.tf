# ---------------------------------------------------------------------------------------------------------------------
# module: amz_server
# Used to create a Windows Server instance on AWS EC2

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
  # filter {
  #   name   = "owner-alias"
  #   values = ["amazon"]
  # }
  name_regex = "^amzn2-ami-hvm-.*x86_64-gp2$"
  owners     = ["amazon"]
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
    values = [var.vpc_name]
  }
}

data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}
