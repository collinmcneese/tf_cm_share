resource "aws_instance" "client_servers_win" {

  depends_on                  = [aws_instance.a2_servers]
  count                       = length(var.client_servers_win)
  ami                         = data.aws_ami.windows.id
  subnet_id                   = data.aws_subnet.selected.id
  instance_type               = var.client_servers_ec2_type
  vpc_security_group_ids      = [aws_security_group.amz_server_sg.id]
  associate_public_ip_address = true
  get_password_data           = true
  user_data                   = <<USERDATA
  <powershell>
# Configure WinRM
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
net stop winrm
sc.exe config winrm start=auto
net start winrm
</powershell>
USERDATA
  key_name                    = var.aws_key

  root_block_device {
    volume_size = var.system_root_volume_size
  }

  tags = {
    Name           = "${var.system_name_prefix} - ${var.client_servers_win[count.index]}"
    ChefClientName = "${var.client_servers_win[count.index]}"
    X-Contact      = var.contact_tag_value
    X-Dept         = var.department_tag_value
    Date           = formatdate("MMM DD, YYYY", timestamp())
  }
}

resource "null_resource" "win_client_bootstrap" {
  depends_on = [
    aws_security_group_rule.ingress_winrm_http,
    aws_security_group_rule.ingress_winrm_https,
    null_resource.client_bootstrap,
    null_resource.post_bootstrap
  ]
  triggers = {
    instance_ids = join(",", aws_instance.client_servers_win.*.id)
  }

  count = length(aws_instance.client_servers_win.*)

  provisioner "local-exec" {
    command = <<-LOCAL
      knife bootstrap winrm://${aws_instance.client_servers_win[count.index].public_ip} -N ${aws_instance.client_servers_win[count.index].tags.ChefClientName} -P '${rsadecrypt(aws_instance.client_servers_win[count.index].password_data, file(var.aws_key_file_local))}' -U administrator --policy-group test --policy-name default_policy -y
      # knife bootstrap winrm://${aws_instance.client_servers_win[count.index].public_ip} -N ${aws_instance.client_servers_win[count.index].private_dns} -P '${rsadecrypt(aws_instance.client_servers_win[count.index].password_data, file(var.aws_key_file_local))}' -U administrator --policy-group test --policy-name default_policy -y
    LOCAL
  }
}
