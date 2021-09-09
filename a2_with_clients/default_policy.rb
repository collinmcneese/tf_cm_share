# default_policy.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile/

# A name that describes what the system you're building with Chef does.
name 'default_policy'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'default_cookbook'

# Specify a custom source for a single cookbook:
cookbook 'default_cookbook', path: './cookbooks/default_cookbook'
cookbook 'ssh-hardening'

# Attributes for nodes
default['audit']['profiles']['ssh-baseline'] = {
  'url': 'https://github.com/dev-sec/ssh-baseline/archive/refs/heads/master.zip'
}

default['audit']['profiles']['windows-baseline'] = {
  'url': 'https://github.com/dev-sec/windows-baseline/archive/refs/heads/master.zip'
}

# Enable compliance phase
default['audit']['compliance_phase'] = true

# Compliance Phase Configuration Items
default['audit']['fetcher'] = 'chef-server'
default['audit']['reporter'] = 'chef-server-automate'
default['audit']['waiver_file'] = '/var/chef/waivers.yml'

default['inspec_waiver_file_entries'] = []
