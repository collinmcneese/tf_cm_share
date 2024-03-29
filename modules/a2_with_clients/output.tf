output "instance_name_a2_servers" {
  description = "List of Names assigned to the instances"
  value       = aws_instance.a2_servers.*.tags.Name
}

output "public_ip_a2_servers" {
  description = "List of public IP addresses assigned to the instances"
  value       = aws_instance.a2_servers.*.public_ip
}

output "public_dns_a2_servers" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = aws_instance.a2_servers.*.public_dns
}

output "instance_name_client_servers" {
  description = "List of Names assigned to the instances"
  value = [
    aws_instance.client_servers.*.tags.Name,
    aws_instance.client_servers_win.*.tags.Name
  ]
}

output "public_ip_client_servers" {
  description = "List of public IP addresses assigned to the instances"
  value = [
    aws_instance.client_servers.*.public_ip,
    aws_instance.client_servers_win.*.public_ip
  ]
}

output "public_dns_client_servers" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value = [
    aws_instance.client_servers.*.public_dns,
    aws_instance.client_servers_win.*.public_dns
  ]
}

output "win_administrator_passwords" {
  value = [
    for g in aws_instance.client_servers_win : rsadecrypt(g.password_data, file(var.aws_key_file_local))
  ]
}
