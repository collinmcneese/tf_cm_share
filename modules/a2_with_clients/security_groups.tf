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

resource "aws_security_group_rule" "internal_sg_traffic" {
  type              = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  security_group_id        = aws_security_group.amz_server_sg.id
  source_security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rdp_rule" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_winrm_http" {
  type              = "ingress"
  from_port         = 5985
  to_port           = 5985
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_winrm_https" {
  type              = "ingress"
  from_port         = 5986
  to_port           = 5986
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
  from_port         = 4222
  to_port           = 4222
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_data_collector_sg" {
  type                     = "ingress"
  from_port                = 4222
  to_port                  = 4222
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
  from_port  = 4222
  to_port    = 4222
  protocol   = "tcp"
  cidr_blocks = [
    for ip in aws_instance.client_servers :
    "${ip.public_ip}/32"
  ]
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_kibana_cidr" {
  type              = "ingress"
  from_port         = 5601
  to_port           = 5601
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_data_feed_api_cidr" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_data_feed_api_sg" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.amz_server_sg.id
  source_security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_data_feed_mongodb_cidr" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_http_cidr" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}

resource "aws_security_group_rule" "ingress_rule_postgresql_cidr" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidr
  security_group_id = aws_security_group.amz_server_sg.id
}
