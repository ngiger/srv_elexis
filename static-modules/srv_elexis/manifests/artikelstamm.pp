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
  
  ensure_packages['php5', 'php5-fpm']
  
  # Geht noch nach /etc/html/artikelstamm anstelle von /var/www
  file { '/etc/nginx/sites-available/artikelstamm':
    ensure => present,
    content => template("srv_elexis/nginx_artikelstamm.erb"),
    require => Package['nginx'],
  }

  file { '/etc/nginx/sites-enabled/artikelstamm':
    ensure  => link,
    target  => '/etc/nginx/sites-available/artikelstamm',
    require => File['/etc/nginx/sites-available/artikelstamm'],
  }
  
}