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

  name_regex = "^amzn2-ami-hvm-.*x86_64-gp2$"
  owners     = ["amazon"]
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
