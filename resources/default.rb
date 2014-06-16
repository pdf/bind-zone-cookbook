#
# Cookbook Name:: bind-zone
# Resource:: default
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

time_regex = [ /^([0-9]+[sSmMhHdDwW])+$/, /\d+/ ]
absolute_host_regex = [ /^([^.]+\.)+$/ ]

actions :create, :delete
default_action :create if defined?(default_action)

attribute :domain, :kind_of => String, :name_attribute => true
attribute :options, :kind_of => Hash, :default => {'type' => 'master'}
attribute :ttl, :regex => time_regex, :default => '1h'
attribute :nameserver, :regex => absolute_host_regex
attribute :contact, :regex => absolute_host_regex
attribute :refresh, :regex => time_regex, :default => '1d'
attribute :retry, :regex => time_regex, :default => '2h'
attribute :expire, :regex => time_regex, :default => '1000h'
attribute :minimum, :regex => time_regex, :default => '2d'

attribute :records, :kind_of => Array, :default => Array.new

attribute :node_query, :kind_of => [Hash, FalseClass], :default => nil

attribute :reverse_zone, :kind_of => [Array, FalseClass], :default => false

def initialize(*args)
  super
  @action = :create
end

# Override node_query accessor to set the query dynamically, based on the domain
def node_query( query=nil )
  if query.nil? and @node_query.nil?
    key = 'domain:%s' % [domain]
    {key => [
      {
        :name => ['name'],
        :value => 'ipaddress'
      }
    ]}
  else
    set_or_return( :node_query, query, :kind_of => [Hash, FalseClass] )
  end
end
