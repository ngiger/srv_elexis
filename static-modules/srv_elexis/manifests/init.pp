# vi: set ft=ruby :
# kate: replace-tabs on; indent-width 2; indent-mode cstyle; syntax ruby
# == Class: srv_elexis
#
# Full description of class srv_elexis here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { srv_elexis:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Niklaus Giger <niklaus.giger@member.fsf.org>
#
# === Copyright
#
# Copyright 2013 Niklaus Giger <niklaus.giger@member.fsf.org>
#

class srv_elexis {

  include srv_elexis::config
  ensure_packages['git', 'unzip', 'dlocate', 'mlocate', 'htop', 'curl', 'etckeeper', 'unattended-upgrades', 'fish', 'mosh',
                  'ntpdate', 'anacron', 'maven', 'ant', 'ant-contrib', 'sudo', 'screen', 'nginx', 'postgresql', 'wget']
  
  file {'/etc/gitconfig':
  content => "# $::srv_elexis::config::managed_note
[user]
        email = niklaus.giger@member.fsf.org
        user = Niklaus Giger
[credential]
        helper = cache --timeout=3600
# Set the cache to timeout after 1 hour (setting is in seconds)
",
    mode => 0644,
    }
  
  ensure_packages['nginx', 'openssl']
  file {          "/etc/nginx/sites-enabled/$fqdn":
    target => "/etc/nginx/sites-available/$fqdn",
    ensure => link,
    owner => root,
    group => root,
    require => File["/etc/nginx/sites-available/$fqdn"],
  }
  file {          "/etc/nginx/sites-enabled/download.elexis.info":
    target => "/etc/nginx/sites-available/download.elexis.info",
    ensure => link,
    owner => root,
    group => root,
  }

  file {"/etc/nginx/ssl":
    ensure => directory,
    owner => root,
    group => root,
    require => Package['nginx'],
  }

  exec {'/etc/nginx/ssl/srv.elexis.info.cert':
    creates => "/etc/nginx/ssl/srv.elexis.info.cert",
    command => '/usr/bin/openssl req -days 1830 -subj "/C=CH/ST=Glarus/L=Mollis/O=Elexis Opensource community/CN=srv.elexis.info/EM=niklaus.giger@member.fsf.org" -nodes -new -x509  -keyout srv.elexis.info.key -out srv.elexis.info.cert',
    cwd     => '/etc/nginx/ssl',
    require => File['/etc/nginx/ssl'],
    notify => Service['nginx'],
  }
  
  file { "/etc/nginx/sites-available/$fqdn":
  content => "# $::srv_elexis::config::managed_note
server {
  listen 443;
  server_name  $fqdn;
  allow all;
  ssl on;
  ssl_certificate_key /etc/nginx/ssl/srv.elexis.info.key;
  ssl_certificate     /etc/nginx/ssl/srv.elexis.info.cert;

  location /jenkins/ {
    proxy_pass              http://localhost:8080;
    proxy_connect_timeout   150;
    proxy_send_timeout      100;
    proxy_read_timeout      100;
    proxy_buffers           4 32k;
    client_max_body_size    8m;
    client_body_buffer_size 128k;
  }
}
",  require => [ Package['nginx'], Exec['/etc/nginx/ssl/srv.elexis.info.cert'], ],
    owner => root,
    group => root,
    notify => Service['nginx'],
  }
  file { "/etc/nginx/sites-available/download.elexis.info":
  content => "# $::srv_elexis::config::managed_note
server {
  listen 80;
  server_name  download.elexis.info;
  root /home/jenkins/downloads;
  autoindex on;
  allow all;
}
",  require => Package['nginx'],
    owner => root,
    group => root,
    notify => Service['nginx'],
  }
  service{'nginx':
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    provider => 'debian',
    require => Package['nginx'],
  }
  
  # The config writer personal choice
  $editor_default = hiera('editor::default', '/usr/bin/vim.nox')  
  $editor_package = hiera('editor::package', 'vim-nox')
  package{ [ $editor_package ]: ensure => present, }
  
  exec {'set_default_editor':
    command => "update-alternatives --set editor ${editor_default}",
    require => Package[$editor_package],
    path    => "/usr/bin:/usr/sbin:/bin:/sbin",
    environment => 'LANG=C',
    unless  => "update-alternatives --display editor --quiet | grep currently | grep ${editor_default}"
  }
  
}
