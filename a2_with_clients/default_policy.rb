# default_policy.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile/

# A name that describes what the system you're building with Chef does.
name 'default_policy'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'chef-client::default', 'chef-client::service', 'ssh-hardening::default', 'audit::default'

# Specify a custom source for a single cookbook:
# cookbook 'example_cookbook', path: '../cookbooks/example_cookbook'

# Attributes for nodes
default['audit']['profiles']['ssh-baseline'] = {
  'git': 'https://github.com/dev-sec/ssh-baseline',
}

default['audit']['fetcher'] = 'chef-server'
default['audit']['reporter'] = %w(chef-server-automate json-file)
# default['audit']['reporter'] = 'json-file'
# default['audit']['json_file']['location'] = '/tmp/audit_report.json'

if Chef::VERSION.to_i >= 15
  default['chef_client']['config']['audit_mode'] = ":disabled"
end

if Chef::VERSION.to_i < 13
  default['audit']['inspec_version'] = '1.6.0'
end

default['audit']['waiver_file'] = '/var/chef/waivers.yml'
