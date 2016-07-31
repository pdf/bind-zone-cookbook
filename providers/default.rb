#
# Cookbook Name:: bind-zone
# Provider:: default
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

require 'ipaddr'

action :create do
  records = @new_resource.records.map do |r|
    Mash.from_hash(r) unless r.is_a? Mash
  end

  unless @new_resource.node_query == false
    if Chef::Config[:solo]
      Chef::Log.fatal!('This provider uses search. Chef Solo does not support search.')
    end
    @new_resource.node_query.each do |query, map|
      query_nodes = search(:node, query)
      query_nodes.each do |query_node|
        map.each do |m|
          m = Mash.from_hash(m) unless m.is_a? Mash
          if !m or !m[:name]
            Chef::Log.warn('Invalid node map: %s' % [m])
            next
          end
          name = m[:name].map do |path|
            if path == 'name'
              result = query_node.name
            else
              result = get_path(query_node, *path.split('.'))
            end

            if result.nil?
              Chef::Log.warn('Empty name for node (%s) at: %s' % [query_node.name, path])
              nil
            elsif !result.is_a?(String)
              Chef::Log.warn('Non-string name for node (%s) at: %s' % [query_node.name, path])
              nil
            end
            result
          end.compact.join('.')

          if name.nil? or name.empty?
            Chef::Log.warn('Empty name for node (%s) at: %s' % [query_node.name, m[:value]])
            next
          end

          value = get_path(query_node, *m[:value].split('.'))
          if value.nil?
            Chef::Log.warn('Empty value for node (%s) at: %s' % [query_node.name, m[:value]])
            next
          elsif !value.is_a?(String)
            Chef::Log.warn('Non-string value for node (%s) at: %s' % [query_node.name, m[:value]])
            next
          end

          begin
            ipaddr = IPAddr.new(value)
          rescue IPAddr::InvalidAddressError
            Chef::Log.warn('Invalid IP address for node (%s) at: %s' % [query_node.name, m[:value]])
            next
          end

          record = Mash.new(:name => name, :value => value)
          if ipaddr.ipv4?
            record[:type] = 'A'
          elsif ipaddr.ipv6?
            record[:type] = 'AAAA'
          else
            Chef::Log.warn('Unknown IP version for node (%s) at: %s' % [query_node.name, m[:value]])
            next
          end

          records << record
        end
      end
    end
  end

  # Strip domain from names
  # Upcase type
  # Ensure TXT records are wrapped in quotes
  # Reject invalid records
  records.map! do |r|
    r[:name].sub!(/\.#{@new_resource.domain}$/, '') ; r
    r[:type].upcase!
    case r[:type]
    when 'TXT'
      r[:value] = '"' + r[:value] unless r[:value].start_with? '"'
      r[:value] += '"' unless r[:value].end_with? '"'
    end
    valid_record?(r) ? r : nil
  end

  records.compact!
  records.uniq!
  records.sort!{ |a, b| [a[:name], a[:type], a[:priority], a[:value]] <=> [b[:name], b[:type], b[:priority], b[:value]] }

  # Underscored domain since periods may be path separators
  underscored_domain = @new_resource.domain.gsub(/\./, '_')

  # Generate initial serial
  node.set_unless[:bind][:serials][underscored_domain] = Time.now.strftime('%Y%m%d') + '00'

  config_file = ::File.join(node[:bind][:config_path], '%s.conf' % [@new_resource.domain])
  zone_file = ::File.join(node[:bind][:zone_path], 'db.%s' % [@new_resource.domain])
  zone_file_records = ::File.join(node[:bind][:zone_path], 'db.%s-records' % [@new_resource.domain])

  template config_file do
    source 'zone.conf.erb'

    helpers(::BindZone::Helpers)

    cookbook 'bind-zone'
    user 'root'
    group node[:bind][:group]
    mode 00640
    variables(
      :resource => new_resource,
      :zone_file => zone_file,
    )
    notifies :restart, 'service[bind]'
  end

  template zone_file_records do
    source 'db.zone-records.erb'

    cookbook 'bind-zone'
    user 'root'
    group node[:bind][:group]
    mode 00640
    variables(
      :resource => new_resource,
      :records => records,
    )
    notifies :create, 'ruby_block[update_serial_%s]' % [new_resource.domain]
  end

  template zone_file do
    source 'db.zone.erb'

    cookbook 'bind-zone'
    user 'root'
    group node[:bind][:group]
    mode 00640
    variables(
      :serial => node[:bind][:serials][underscored_domain],
      :resource => new_resource,
      :zone_file_records => zone_file_records,
    )
    notifies :reload, 'service[bind]'

    action :nothing
  end

  ruby_block 'update_serial_%s' % [@new_resource.domain] do
    block do
      update = false
      date = Time.now.strftime('%Y%m%d')
      new_serial = date
      old_serial = node[:bind][:serials][underscored_domain]
      if match = %r{^#{date}([0-9]{2})$}.match(old_serial)
        new_serial += '%02d' % [match[-1].to_i + 1]
      else
        new_serial += '00'
      end
      node.set[:bind][:serials][underscored_domain] = new_serial
    end

    action :nothing
    notifies :create, 'template[%s]' % [zone_file]
    notifies :create, 'template[%s]' % [node[:bind][:local_file]]
  end

end

action :delete do
end

private
# Retrive a nested attribute from a domain
def get_path( source_node, *path )
  h = source_node.to_hash
  path.inject(h) { |obj, item| obj[item.to_s] || break }
end

# TODO: More robust, type-based validation
def valid_record?( record )
  !record[:name].nil? and !record[:type].nil? and !record[:value].nil? and
    !record[:name].empty? and !record[:type].empty? and !record[:value].empty?
end
