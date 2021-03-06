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
class srv_elexis::mysql(
) inherits srv_elexis {
  
  class { '::mysql::server':
    root_password    => 'foo',
    override_options => { 'mysqld' =>
      { 'max_connections' => '1024' },
        'default_engine' => "innodb",
    }
  }
  class { 'mysql::client': }
  
  class { 'mysql::server::backup':
    backupuser     => 'backup',
    backuppassword => 'elexisTest',
    backupdir      => '/opt/backups',
    backupdirgroup => 'backup',
    backuprotate   => '15',
  }

}