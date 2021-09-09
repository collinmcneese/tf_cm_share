#
# Cookbook:: default_cookbook
# Recipe:: default
#

include_recipe 'default_cookbook::windows' if windows?
include_recipe 'default_cookbook::linux' if linux?
