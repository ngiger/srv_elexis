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
class srv_elexis::wiki(
) inherits srv_elexis {
# class { 'apache': mpm_module => 'prefork', }
    class { 'apache':
      default_vhost => false,
    }


#    apache::mod { 'mpm_module': => false }
# see http://puppetlabs.com/blog/module-of-the-week-martasd-mediawiki
  class { 'mediawiki': 
    server_name => "$fqdn", 
    admin_email => 'niklaus.giger@member.fsf.org', 
    db_root_password => 'really_really_long_password', 
    tarball_url => 'http://download.wikimedia.org/mediawiki/1.17/mediawiki-1.17.0.tar.gz', 
    doc_root => '/var/www/wiki',
    max_memory => '1024',
  }
  
  mediawiki::instance { 'my_wiki1': 
    server_name => "$fqdn", 
    db_password => 'really_long_password', 
    db_name => 'wiki1', 
    db_user => 'wiki1_user', 
    port => '81', 
    ensure => 'present' 
  } 
  
  file { '/var/www': 
    ensure => 'directory', 
    owner => 'root', 
    group => 'root',
    mode => '0755', 
  }

  file { '/var/www/wiki': 
    ensure => 'directory', 
    owner => 'root', 
    group => 'root',
    mode => '0755', 
  }

# - See more at: http://puppetlabs.com/blog/module-of-the-week-martasd-mediawiki#sthash.PNaM8Oya.dpuf}

}