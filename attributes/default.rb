default[:bind][:version] = 9
default[:bind][:user] = 'bind'
default[:bind][:group] = 'bind'
default[:bind][:local_file] = '/etc/bind/named.conf.local'
default[:bind][:options_file] = '/etc/bind/named.conf.options'
default[:bind][:log_file] = '/var/log/named/bind.log'
default[:bind][:zone_path] = '/etc/bind/zone.d'
default[:bind][:config_path] = '/etc/bind/conf.d'
default[:bind][:cache_path] = '/var/cache/bind'
default[:bind][:serials] = Mash.new
default[:bind][:options] = Mash.new(
  'allow-query' => ['any'],
  'allow-recursion' => ['none'],
  'allow-transfer' => ['none'],
  'auth-nxdomain' => 'no',
)
