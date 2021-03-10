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

resource "null_resource" "fetch_automate_credentials" {
  depends_on = [
    aws_instance.a2_servers,
  ]
  triggers = {
    instance_ids = join(",", aws_instance.a2_servers.*.id)
  }

  count = length(aws_instance.a2_servers.*)

  provisioner "local-exec" {
    command = <<-LOCAL
      if grep -q '${aws_instance.a2_servers[0].public_ip}' ~/.ssh/known_hosts ; then sed -i '/${aws_instance.a2_servers[0].public_ip}/d' ~/.ssh/known_hosts ; fi
      ssh-keyscan -H ${aws_instance.a2_servers[0].public_ip} >> ~/.ssh/known_hosts
      scp -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip}:automate-credentials.toml automate-credentials.toml
    LOCAL
  }
}
