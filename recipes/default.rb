#
# Cookbook Name:: observium
# Recipe:: default
#

require 'rubygems'

include_recipe 'apache2'
include_recipe 'mysql::server'

# http://www.cryptocracy.com/blog/2014/04/29/five-things-i-hate-about-chef/
# require mysql fails due to https://sethvargo.com/using-gems-with-chef/

# Run first because of dependencies for mysql gem
%w(mcrypt libapache2-mod-php5 php5-cli php5-mysql php5-gd php5-mcrypt php5-json php-pear snmp fping
   mysql-server mysql-client python-mysqldb rrdtool subversion whois mtr-tiny ipmitool
   graphviz imagemagick build-essential libmysqlclient-dev).each do |p|
  package p do
    action :install
  end
end
package ['sendmail', 'sendmail-bin'] do
  action :install if node['observium']['alert']['email_enable'] == true
end

chef_gem 'mysql2' do
  compile_time false
  action :install
end

Gem.clear_paths

# Ruby code in the ruby_block resource is evaluated with other resources during
# convergence, whereas Ruby code outside of a ruby_block resource is evaluated
# before other resources, as the recipe is compiled.
mysql_database_user node['observium']['db']['user'] do
  connection(
    host: node['observium']['db']['host'],
    username: 'root',
    password: node['mysql']['server_root_password']
  )
  password node['observium']['db']['password']
  action :create
end

mysql_database node['observium']['db']['db_name'] do
  connection(
    host: node['observium']['db']['host'],
    username: 'root',
    password: node['mysql']['server_root_password']
  )
  encoding 'UTF8'
  owner node['observium']['db']['user']
  action :create
end

mysql_database_user node['observium']['db']['user'] do
  connection(
    host: node['observium']['db']['host'],
    username: 'root',
    password: node['mysql']['server_root_password']
  )
  database_name node['observium']['db']['db_name']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

if node['observium']['community_edition'] == true
  # Community Edition
  ark 'observium' do
    url 'http://www.observium.org/observium-community-latest.tar.gz'
    prefix_root '/opt'
    path '/opt'
    home_dir node['observium']['install_dir']
    owner node['apache']['user']
    action :put
  end
else
  # Paid Edition
  subversion 'observium' do
    repository 'http://svn.observium.org/svn/observium/branches/stable'
    svn_username node['observium']['svn']['username']
    svn_password node['observium']['svn']['password']
    destination node['observium']['install_dir']
    revision 'HEAD'
    action :checkout
  end
end

template "#{node['observium']['install_dir']}/config.php" do
  source 'config.php.erb'
  owner node['apache']['user']
  group node['apache']['group']
  mode 0766
end

directory "#{node['observium']['install_dir']}/rrd" do
  owner node['apache']['user']
  group node['apache']['group']
  mode 00755
  action :create
end

directory "#{node['observium']['install_dir']}/logs" do
  owner node['apache']['user']
  group node['apache']['group']
  mode 00755
  action :create
end

# Make sure mcrypt is enabled
execute 'php5enmod mcrypt' do

end

# only run the execute blocks, if not allready set up
if node['observium']['installed'] == false

  # Setup the MySQL database and insert the default schema
  execute './discovery.php -u' do
    cwd node['observium']['install_dir']
    # not_if ''
  end

  # create admin
  execute './adduser.php admin admin 10' do
    cwd node['observium']['install_dir']
  end

  # Initial discovery
  execute './discovery.php -h all' do
    cwd node['observium']['install_dir']
  end

  # Initial polling
  execute './poller.php -h all' do
    cwd node['observium']['install_dir']
  end
  node.normal['observium']['installed'] = true
  node.save unless Chef::Config[:solo]
end

web_app 'observium' do
  server_name node['observium']['server_name']
  server_aliases node['observium']['server_aliases']
  docroot "#{node['observium']['install_dir']}/html/"
  allow_override 'all'
end

# setup crons

cron_d 'discovery-all' do
  minute '33'
  hour '*/6'
  command "#{node['observium']['install_dir']}/discovery.php -h all \
>> /dev/null 2>&1"
  user 'root'
end

cron_d 'discovery-new' do
  minute '*/5'
  command "#{node['observium']['install_dir']}/discovery.php -h new \
>> /dev/null 2>&1"
  user 'root'
end

cron_d 'poller-wrapper' do
  minute '*/5'
  command "#{node['observium']['install_dir']}/poller-wrapper.py \
#{node['observium']['config']['poller_threads']} >> /dev/null 2>&1"
  user 'root'
end
