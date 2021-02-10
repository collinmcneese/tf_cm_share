# tf_cm_share

Terraform configurations.

## Modules Included

- __modules/a2_with_clients__ : Used to create an all-in-one Chef Automate(plus CS & Builder) server along with clients which are bootstrapped to the server on AWS.  Also creates associated security groups which will be needed for the instances.

## Usage

### a2_with_clients

#### Getting Started

- Perform work from the `a2_with_clients` top-level directory.
- Copy `main.tf.example` to be `main.tf` and update all values.
- run `terraform init`

#### Working with the Infrastructure

- verify that `aws` cli is installed and you are properly authenticated (`okta_aws` is suggested [https://github.com/chef/okta_aws])
- Populate values in created `main.tf` which was copied from `main.tf.example`.
- Execute `terraform plan` to confirm there are no errors.
- Execute `terraform apply` to build the infrastructure.  This will create with module source of __modules/a2_with_clients__.  Once completed, it will also create a local `.chef` directory at the current location, allowing for `knife` access to the Chef Infra Server instance.  Total creation time is __~10 minutes__.
- Execute `terraform destroy` when completed to clean-up any resources created.
