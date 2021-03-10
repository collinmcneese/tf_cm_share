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
      ssh-keyscan ${aws_instance.a2_servers[0].public_ip} >> ~/.ssh/known_hosts
      ssh-keyscan ${aws_instance.client_servers[count.index].public_ip} >> ~/.ssh/known_hosts
      # testuserkey=$(ssh -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip} 'cat testuser.pem')
      # validatorkey=$(ssh -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip} 'cat a2local-validator.pem')
      if [ ! -d .chef ] ; then mkdir .chef ; fi
      scp -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip}:testuser.pem .chef/testuser.pem
      # scp -i ${var.aws_key_file_local} ec2-user@${aws_instance.a2_servers[0].public_ip}:a2local-validator.pem .chef/a2local-validator.pem
      cat << CONFIG > .chef/config.rb
current_dir = File.dirname(__FILE__)
  log_level                :info
  log_location             STDOUT
  node_name                'testuser'
  client_key               "#{current_dir}/testuser.pem"
  chef_server_url          'https://${aws_instance.a2_servers[0].public_dns}/organizations/a2local'
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

resource "null_resource" "post_bootstrap" {
  depends_on = [
    null_resource.client_bootstrap,
  ]

  triggers = {
    instance_ids = join(",", aws_instance.client_servers.*.id)
  }

  provisioner "local-exec" {
    command = <<-LOCAL_POST
      for n in `knife node list` ; do ssh-keyscan $n >> ~/.ssh/known_hosts ; done
      chef update ssh_policy.rb
      chef push test ssh_policy.lock.json
      for n in `knife node list` ; do scp waivers.yml ec2-user@$n:/tmp/waivers.yml ;  ssh ec2-user@$n "sudo mkdir -p /var/chef/ ; sudo cp /tmp/waivers.yml /var/chef/" ; done
      for n in `knife node list` ; do knife node policy set $n test ssh_policy ; done
      knife ssh -x ec2-user "name:*" "sudo chef-client"
    LOCAL_POST
  }
}
