default['mysql']['server_root_password'] = 'root'
default['mysql']['data_dir'] = '/data'

default['mysql']['version'] = '5.5'
default['apache']['user'] = 'www-data'
default['apache']['group'] = 'www-data'
default['apache']['version'] = '2.4'

default['observium']['installed'] = false
default['observium']['install_dir'] = '/opt/observium'
default['observium']['server_name'] = 'observium.example.com'
default['observium']['server_aliases'] = ['observium.localhost']
default['observium']['community_edition'] = true

default['observium']['device_status']['devices'] = true
default['observium']['device_status']['ports'] = true
default['observium']['device_status']['errors'] = true
default['observium']['device_status']['services'] = true
default['observium']['device_status']['bgp'] = true
default['observium']['device_status']['uptime'] = true

default['observium']['config']['fping_path'] = '/usr/bin/fping'
default['observium']['config']['collectd_dir'] = '/var/lib/collectd/rrd/'
default['observium']['config']['poller_threads'] = '16'

default['observium']['db']['host'] = 'localhost'
default['observium']['db']['user'] = 'observium'
default['observium']['db']['password'] = 'observium'
default['observium']['db']['db_name'] = 'observium'

default['observium']['alert']['enable'] = true
default['observium']['alert']['email'] = 'mail@example.com'
default['observium']['alert']['default_only'] = true
default['observium']['alert']['email_enable'] = true
default['observium']['alert']['uptime_warning'] = '86400'
default['observium']['alert']['port_status'] = false

default['observium']['svn']['username'] = 'changeme'
default['observium']['svn']['password'] = 'changeme'
