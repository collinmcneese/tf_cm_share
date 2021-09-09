#
# Cookbook:: default_cookbook
# Recipe:: linux
#

# Git should be installed on the system
package 'git'
package 'wget'
package 'vim'

tag('mytag')
tag('my_other_tag')
tag('tag:::with_characters-too')

chef_client_systemd_timer 'Run Chef Infra Client as a systemd timer' do
  interval '10min'
  delay_after_boot '5min'
  splay '5min'
end

directory '/var/chef' do
  action :create
end

file '/var/chef/waivers.yml' do
  action :touch
end

node.override['inspec_waiver_file_entries'] = [
  {
    control: 'sshd-15',
    justification: 'Reason for waiving this control in plain text.',
    action: 'add',
  },
  {
    control: 'sshd-21',
    justification: 'Reason for waiving this control in plain text.',
    action: 'add',
  },
  {
    control: 'sshd-50',
    justification: 'Reason for waiving this control in plain text.',
    action: 'add',
  },
]

node['inspec_waiver_file_entries'].each do |wv|
  inspec_waiver_file_entry wv['control'] do
    backup wv['backup']
    expiration wv['expiration']
    file_path node['audit']['waiver_file']
    justification wv['justification']
    run_test wv['run_test'] || false
    action wv['action'].to_sym
  end
end

include_recipe 'ssh-hardening'
