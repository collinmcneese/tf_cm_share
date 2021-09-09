#
# Cookbook:: default_cookbook
# Recipe:: windows
#

directory 'C:/chef/log' do
  recursive true
end

chef_client_scheduled_task 'Run Chef Infra Client as a scheduled task' do
  accept_chef_license true
  frequency 'minute'
  frequency_modifier 10
  log_directory 'C:/chef/log'
  log_file_name 'chef-client.log'
  action :add
end

file 'C:/chef/waivers.yml' do
  action :touch
end

node.override['audit']['waiver_file'] = 'C:/chef/waivers.yml'

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
