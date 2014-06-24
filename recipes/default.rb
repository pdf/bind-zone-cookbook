#
# Cookbook Name:: bind-zone
# Recipe:: default
#
# Copyright (c) 2014 Peter Fern
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

package "bind#{node[:bind][:version]}" do
  action :install
end

directory ::File.dirname(node[:bind][:log_file]) do
  owner 'bind'
  group 'bind'
  mode 00750
  action :create
end

directory node[:bind][:zone_path] do
  owner 'root'
  group node[:bind][:group]
  mode 00750
  action :create
end

directory node[:bind][:config_path] do
  owner 'root'
  group node[:bind][:group]
  mode 00750
  action :create
end

service "bind" do
  service_name "bind#{node[:bind][:version]}"
  supports :status => true, :reload => true, :restart => true
  action [:enable]
end

template node[:bind][:local_file] do
  source 'named.conf.local.erb'

  variables({
    :zones => node[:bind][:serials].keys.sort,
    :config_path => node[:bind][:config_path],
  })
  notifies :restart, 'service[bind]'
  action :create
end

template node[:bind][:options_file] do
  source 'named.conf.options.erb'

  helpers(BindZone::Helpers)

  variables({
    :options => node[:bind][:options],
    :log_file => node[:bind][:log_file],
    :cache_path => node[:bind][:cache_path],
  })
  notifies :restart, 'service[bind]'
  action :create
end
