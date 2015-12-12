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

class srv_elexis::nginx inherits srv_elexis {

  # /usr/share/nginx/html/index.html
  # /var/www/html
  #  volumes         => ['/var/lib/couchdb', '/var/log'],
  #volumes_from    => '6446ea52fbc9',
  include git
  git::config { 'user.name':
    value => 'Niklaus Giger',
  }

  $letsencrypt_vcs = '/home/letsencrypt'
  $renew_file = '/usr/local/bin/letsencrypt_renew'

  vcsrepo {$letsencrypt_vcs:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/letsencrypt/letsencrypt',
  }

  git::config { 'user.email':
    value => 'niklaus.giger@member.fsf.org',
  }

  include docker
  docker::image { 'nginx':
    docker_file => "${docker_files}/nginx/Dockerfile",
#    notify => Docker::Run['nginx'],
  }
  include srv_elexis::config

  file {"/etc/nginx/ssl":
    ensure => directory,
    owner => root,
    group => root,
  }
  file { "/etc/nginx/sites-available/jenkins.$::domain":
    ensure => absent,
  }

  file { "/etc/nginx/sites-enabled/jenkins.$::domain":
  content => "# $::srv_elexis::config::managed_note
# from https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-with-ssl-as-a-reverse-proxy-for-jenkins
# anderung zwei
server {
    listen 80;
    server_name  jenkins.$::domain;
    return 301 https://jenkins.$::domain\$request_uri;
}

server {

    listen 443;
    server_name  jenkins.$::domain;

    ssl_certificate         /etc/letsencrypt/live/jenkins.$::domain/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/jenkins.$::domain/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/jenkins.$::domain/fullchain.pem;

    ssl on;
    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    access_log            /var/log/nginx/jenkins.access.log;

    location / {

      proxy_set_header        Host \$host;
      proxy_set_header        X-Real-IP \$remote_addr;
      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;

      # Jenkins URL of configure must point to  https://jenkins.$::domain
      # Fix the 'It appears that your reverse proxy set up is broken' error.
      proxy_pass          http://jenkins.$::domain:8080;
      proxy_read_timeout  90;

      proxy_redirect      http://jenkins.$::domain:8080 https://jenkins.$::domain;
      proxy_redirect      http://localhost:8080 https://jenkins.$::domain;
    }
  }
",  owner => root,
    group => root,
    backup => false, # we don't want to keep them, as nginx would read them, too
    notify => Docker::Image['nginx'],
    require =>  Exec[$renew_file],
  }

  file {$renew_file:
   content => "#!/bin/bash
# $::srv_elexis::config::managed_note
# We want to get one certificate valid for all our sub-domains. Therefore we must put
# several -d directives in 1 line.
# To renew a certificate, simply run letsencrypt again providing the same values when prompted.
# There is a limit of 5 certificates for 7 days!
# Logfile is /var/log/letsencrypt/letsencrypt.log
cd $letsencrypt_vcs
git pull
/etc/init.d/nginx stop
./letsencrypt-auto --standalone certonly --renew-by-default  -d artikelstamm.$::domain -d srv.$::domain -d wiki.$::domain -d jenkins.$::domain
/etc/init.d/nginx start
",  owner => root,
    require =>  [Vcsrepo[$letsencrypt_vcs]],
    mode => 0755,
    group => root,
  }

exec { $renew_file:
  creates => '/etc/letsencrypt/live/jenkins.elexis.info/fullchain.pem',
  require => [File[$renew_file]],
}
cron { $renew_file:
  command => "$renew_file",
  user    => root,
  month   => [3,6,9,12],
  monthday => 1,
  hour    => 2,
  minute  => 0
}

file { "/etc/nginx/sites-enabled/srv.$::domain":
   content => "# $::srv_elexis::config::managed_note
server {
  listen 443;
  server_name  srv.$::domain;
  allow all;
  ssl on;
  ssl_certificate         /etc/letsencrypt/live/srv.$::domain/fullchain.pem;
  ssl_certificate_key     /etc/letsencrypt/live/srv.$::domain/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/srv.$::domain/fullchain.pem;

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
"
}

  file {          "/etc/nginx/sites-enabled/default":
    ensure => absent,
    owner => root,
    group => root,
  }

  file { "/etc/nginx/sites-enabled/download.$::domain":
  content => "# $::srv_elexis::config::managed_note
server {
  listen 80;
  server_name  download.$::domain;
  return 301 https://download.$::domain\$request_uri ;
}

server {
  listen 443;
  server_name  download.$::domain;
  allow all;
  ssl on;
  ssl_certificate         /etc/letsencrypt/live/download.$::domain/fullchain.pem;
  ssl_certificate_key     /etc/letsencrypt/live/download.$::domain/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/download.$::domain/fullchain.pem;

  autoindex on;
  root /home/jenkins/downloads;

}
",  owner => root,
    backup => false, # we don't want to keep them, as nginx would read them, too
    group => root,
    notify => Docker::Image['nginx'],
  }

}
