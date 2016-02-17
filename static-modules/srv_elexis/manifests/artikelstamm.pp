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
class srv_elexis::artikelstamm(
) inherits srv_elexis {

  File {
    owner => 'root',
    group => 'root',
  }

  file { "/home/www/artikelstamm.$::domain":
    ensure => directory,
    owner => 'jenkins',
    require => [File['/home/www'],
      User['jenkins'],
#      Group['jenkins'],
    ],
  }

  ensure_packages(['php5', 'php5-fpm'])

  file { "/etc/nginx/sites-available/artikelstamm.$::domain":
    ensure => absent,
  }

  file { "/etc/nginx/sites-enabled/artikelstamm.$::domain":
  content => "# $::srv_elexis::config::managed_note
server {
  listen 80;
  server_name  artikelstamm.$::domain;
  return 301 https://artikelstamm.$::domain\$request_uri;
}

server {
  listen 443;
  server_name  artikelstamm.$::domain;
  root /home/www/artikelstamm.$::domain;
  index index.html index.htm index.php;
  autoindex on;
  allow all;
  ssl_certificate         /etc/letsencrypt/live/artikelstamm.$::domain/fullchain.pem;
  ssl_certificate_key     /etc/letsencrypt/live/artikelstamm.$::domain/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/artikelstamm.$::domain/fullchain.pem;

  ssl on;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
  ssl_prefer_server_ciphers on;
  location ~ \\.php\$ {
    try_files \$uri =404;
    fastcgi_split_path_info ^(.+\\.php)(/.+)\$;
    fastcgi_index index.php;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include /etc/nginx/fastcgi_params;
  }

}
",  owner => root,
    backup => false, # we don't want to keep them, as nginx would read them, too
    group => root,
    notify => Docker::Image['nginx'],
  }
}