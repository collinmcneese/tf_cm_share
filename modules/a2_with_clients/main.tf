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
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  owners = ["amazon"]
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
################################################################################
resource "aws_security_group" "amz_server_sg" {
  vpc_id      = data.aws_vpc.selected.id
  name        = var.security_group_name
  description = "Security Group created by Terraform plan."
  tags = {
    Name      = var.security_group_name
    X-Contact = var.contact_tag_value
    X-Dept    = var.department_tag_value
    Date      = formatdate("MMM DD, YYYY", timestamp())
  }
}

resource "aws_security_group_rule" "ingress_rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_https_cidr" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_https_sg" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.amz_server_sg.id
  source_security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_data_collector_cidr" {
  type              = "ingress"
  from_port         = 4442
  to_port           = 4442
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_data_collector_sg" {
  type                     = "ingress"
  from_port                = 4442
  to_port                  = 4442
  protocol                 = "tcp"
  security_group_id        = aws_security_group.amz_server_sg.id
  source_security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.amz_server_sg.id
}

################################################################################
resource "aws_instance" "a2_servers" {
  count                       = length(var.a2_servers)
  ami                         = data.aws_ami.amazon-linux-2.id
  subnet_id                   = data.aws_subnet.selected.id
  instance_type               = var.system_instance_type
  vpc_security_group_ids      = [aws_security_group.amz_server_sg.id]
  associate_public_ip_address = true
  user_data                   = var.system_init_user_data
  key_name                    = var.aws_key

  root_block_device {
    volume_size = var.system_root_volume_size
  }

  tags = {
    Name      = "${var.system_name_prefix} - ${var.a2_servers[count.index]}"
    X-Contact = var.contact_tag_value
    X-Dept    = var.department_tag_value
    Date      = formatdate("MMM DD, YYYY", timestamp())
  }

  provisioner "remote-exec" {
    inline = var.provisioner_exec_data_a2
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.aws_key_file_local)
    }
  }
}

resource "aws_instance" "client_servers" {
  depends_on                  = [aws_instance.a2_servers]
  count                       = length(var.client_servers)
  ami                         = data.aws_ami.amazon-linux-2.id
  subnet_id                   = data.aws_subnet.selected.id
  instance_type               = var.system_instance_type
  vpc_security_group_ids      = [aws_security_group.amz_server_sg.id]
  associate_public_ip_address = true
  user_data                   = var.system_init_user_data
  key_name                    = var.aws_key

  root_block_device {
    volume_size = var.system_root_volume_size
  }

  tags = {
    Name      = "${var.system_name_prefix} - ${var.client_servers[count.index]}"
    X-Contact = var.contact_tag_value
    X-Dept    = var.department_tag_value
    Date      = formatdate("MMM DD, YYYY", timestamp())
  }

  provisioner "remote-exec" {
    inline = var.provisioner_exec_data_client
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.aws_key_file_local)
    }
  }
}

################################################################################
resource "aws_security_group_rule" "ingress_rule_https_clients" {
  depends_on = [aws_instance.client_servers]
  type       = "ingress"
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
  cidr_blocks = [
    for ip in aws_instance.client_servers :
    "${ip.public_ip}/32"
  ]
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_data_collector_clients" {
  depends_on = [aws_instance.client_servers]
  type       = "ingress"
  from_port  = 4442
  to_port    = 4442
  protocol   = "tcp"
  cidr_blocks = [
    for ip in aws_instance.client_servers :
    "${ip.public_ip}/32"
  ]
  security_group_id = aws_security_group.amz_server_sg.id
}

################################################################################
resource "null_resource" "client_bootstrap" {
  depends_on = [
    aws_security_group_rule.ingress_rule_https_clients,
    aws_security_group_rule.ingress_rule_data_collector_clients,
  ]
  triggers = {
    instance_ids = join(",", aws_instance.client_servers.*.id)
  }

  count = length(aws_instance.client_servers.*)

  provisioner "local-exec" {
    command = <<-LOCAL
      if grep -q '${aws_instance.client_servers[count.index].public_ip}' ~/.ssh/known_hosts ; then sed -i '/${aws_instance.client_servers[count.index].public_ip}/d' ~/.ssh/known_hosts ; fi
      if grep -q '${aws_instance.a2_servers[0].public_ip}' ~/.ssh/known_hosts ; then sed -i '/${aws_instance.a2_servers[0].public_ip}/d' ~/.ssh/known_hosts ; fi
      ssh-keyscan -H ${aws_instance.a2_servers[0].public_ip} >> ~/.ssh/known_hosts
      ssh-keyscan -H ${aws_instance.client_servers[count.index].public_ip} >> ~/.ssh/known_hosts
      # testuserkey=$(ssh -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip} 'cat testuser.pem')
      # validatorkey=$(ssh -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip} 'cat a2local-validator.pem')
      if [ ! -d .chef ] ; then mkdir .chef ; fi
      scp -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip}:testuser.pem .chef/testuser.pem
      scp -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip}:a2local-validator.pem .chef/a2local-validator.pem
      cat << CONFIG > .chef/config.rb
current_dir = File.dirname(__FILE__)
  log_level                :info
  log_location             STDOUT
  node_name                'testuser'
  client_key               "#{current_dir}/testuser.pem"
  chef_server_url          'https://${aws_instance.a2_servers[0].public_dns}/organizations/a2local'
  validation_client_name   'a2local-validator'
  validation_key           "#{current_dir}/a2local-validator.pem"
  cache_type               'BasicFile'
  cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
  cookbook_path            ["#{current_dir}/../cookbooks"]
  ssl_verify               :verify_none
CONFIG
      knife ssl fetch https://${aws_instance.a2_servers[0].public_dns}
      berks install
      berks upload
      knife bootstrap ec2-user@${aws_instance.client_servers[count.index].public_ip} -N ${aws_instance.client_servers[count.index].public_dns} -i ${var.aws_key_file_local} --sudo -r 'recipe[chef-client]' -y
    LOCAL
  }
}
