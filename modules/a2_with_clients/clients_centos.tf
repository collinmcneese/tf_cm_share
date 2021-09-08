resource "aws_instance" "client_servers_centos" {

  depends_on                  = [aws_instance.a2_servers]
  count                       = length(var.client_servers_centos)
  ami                         = data.aws_ami.centos.id
  subnet_id                   = data.aws_subnet.selected.id
  instance_type               = var.client_servers_ec2_type
  vpc_security_group_ids      = [aws_security_group.amz_server_sg.id]
  associate_public_ip_address = true
  user_data                   = var.system_init_user_data
  key_name                    = var.aws_key

  root_block_device {
    volume_size = var.system_root_volume_size
  }

  tags = {
    Name      = "${var.system_name_prefix} - ${var.client_servers_centos[count.index]}"
    ChefClientName  = "${var.client_servers_centos[count.index]}"
    X-Contact = var.contact_tag_value
    X-Dept    = var.department_tag_value
    Date      = formatdate("MMM DD, YYYY", timestamp())
  }

  provisioner "remote-exec" {
    inline = var.provisioner_exec_data_client
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "centos"
      private_key = file(var.aws_key_file_local)
    }
  }
}

resource "null_resource" "client_bootstrap_centos" {
  depends_on = [
    null_resource.client_bootstrap,
    null_resource.post_bootstrap
  ]
  triggers = {
    instance_ids = join(",", aws_instance.client_servers_centos.*.id)
  }

  count = length(aws_instance.client_servers_centos.*)

  provisioner "local-exec" {
    command = <<-LOCAL
      if grep -q '${aws_instance.client_servers_centos[count.index].public_ip}' ~/.ssh/known_hosts ; then sed -i '/${aws_instance.client_servers_centos[count.index].public_ip}/d' ~/.ssh/known_hosts ; fi
      ssh-keyscan ${aws_instance.client_servers_centos[count.index].public_ip} >> ~/.ssh/known_hosts
      knife bootstrap centos@${aws_instance.client_servers_centos[count.index].public_ip} -N ${aws_instance.client_servers_centos[count.index].tags.ChefClientName} -i ${var.aws_key_file_local} --sudo --policy_group test --policy_name default_policy -y
    LOCAL
  }
}
