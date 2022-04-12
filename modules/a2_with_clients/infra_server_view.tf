
resource "null_resource" "infra_server_view_create" {
  depends_on = [
    null_resource.post_bootstrap,
  ]

  triggers = {
    instance_ids = join(",", aws_instance.client_servers.*.id)
  }

  provisioner "local-exec" {
    command = <<-LOCAL_POST
      key_data=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' .chef/testuser.pem)
      api_token=$(cat automate-api-token)
      a2_server=${aws_instance.a2_servers[0].public_dns}
      create_server_data="{\"fqdn\": \"$a2_server\", \"id\": \"$a2_server\", \"name\": \"$a2_server\"}"
      create_org_data="{\"admin_key\": \"$key_data\", \"admin_user\": \"testuser\", \"id\": \"a2local\", \"name\": \"a2local\", \"server_id\": \"$a2_server\"}"
      curl --location --insecure --request POST "https://$a2_server/api/v0/infra/servers" --header 'Content-Type: application/json' --header "api-token: $api_token"  -d "$create_server_data" || exit 1
      curl --location --insecure --request POST "https://$a2_server/api/v0/infra/servers/$a2_server/orgs" --header 'Content-Type: application/json' --header "api-token: $api_token"  -d "$create_org_data" || exit 1
    LOCAL_POST
  }
}
