
resource "null_resource" "infra_server_view_create" {
  depends_on = [
    null_resource.post_bootstrap,
  ]

  triggers = {
    instance_ids = join(",", aws_instance.client_servers.*.id)
  }

  provisioner "local-exec" {
    command = <<-LOCAL_POST
      key_data=$(echo -n `cat .chef/testuser.pem` | sed 's/ /\\n/g')
      api_token=$(cat automate-api-token)
      a2_server=${aws_instance.a2_servers[0].public_dns}
      echo $key_data
      echo $api_token
      echo $a2_server
      create_server_data="{\"fqdn\": \"$a2_server\", \"ip_address\": \"127.0.0.1\",\"id\": \"$a2_server\", \"name\": \"$a2_server\"}"
      create_org_data="{\"admin_key\": \"$key_data\", \"admin_user\": \"testuser\", \"id\": \"a2local\", \"name\": \"a2local\", \"server_id\": \"$a2_server\"}"
      curl --location --insecure --request POST "https://$a2_server/api/v0/infra/servers" --header 'Content-Type: application/json' --header "api-token: $api_token"  -d "$create_server_data" || exit 1
      curl --location --insecure --request POST "https://$a2_server/api/v0/infra/servers/$a2_server/orgs" --header 'Content-Type: application/json' --header "api-token: $api_token"  -d "$create_org_data" || exit 1
    LOCAL_POST
  }
}
