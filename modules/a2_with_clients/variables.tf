# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "vpc_name" {
  description = "VPC name to use"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name to use"
  type        = string
}

variable "provisioner_exec_data_a2" {
  description = "Lines to sent to remote-exec provisioner"
  type        = list(string)
  default     = ["echo 'nothing to do'"]
}

variable "provisioner_exec_data_client" {
  description = "Lines to sent to remote-exec provisioner"
  type        = list(string)
  default     = ["echo 'nothing to do'"]
}

variable "aws_profile_name" {
  description = "The name of the aws profile needed for intended use"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "The name of the region in the instance will live"
  type        = string
}

variable "security_group_name" {
  description = "The name of the security group to create/use"
  type        = string
}

variable "security_group_ingress_cidr" {
  description = "CIDR block list to be allowed ingress access to ec2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


variable "a2_ec2_type" {
  description = "The instance type for Chef Automate server"
  type        = string
  default     = "t3.large"
}

variable "client_servers_ec2_type" {
  description = "The instance type Chef Infra Client servers"
  type        = string
  default     = "t3.large"
}

variable "aws_key" {
  description = "Optional name of AWS key pair to use"
  type        = string
  default     = ""
}

variable "aws_key_file_local" {
  description = "Path to AWS key PEM file on local filesystem"
  type        = string
  default     = ""
}

variable "system_init_user_data" {
  description = "User Data block to pass to instance"
  type        = string
  default     = ""
}

variable "a2_servers" {
  description = "Name of systems"
  type        = list(string)
}

variable "client_servers" {
  description = "Name of systems"
  type        = list(string)
}

variable "client_servers_win" {
  description = "Name of systems"
  type        = list(string)
  default     = []
}

variable "client_servers_centos" {
  description = "Name of systems"
  type        = list(string)
  default     = []
}

variable "client_servers_ubuntu" {
  description = "Name of systems"
  type        = list(string)
  default     = []
}

variable "system_root_volume_size" {
  type    = number
  default = 8
}

variable "system_name_prefix" {
  description = "Prefix for the system name as it will be displayed in EC2."
  type        = string
}

variable "system_remote_exec_commands" {
  description = "Commands to run with remote_exec after creation"
  type        = string
  default     = ""
}

variable "contact_tag_value" {
  description = "Contact Information"
  type        = string
}

variable "department_tag_value" {
  description = "Department Information"
  type        = string
}
