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
class srv_elexis::jobs(
) inherits srv_elexis {
  require srv_elexis::config

  File {
    owner => 'jenkins',
    group => 'jenkins',
  }

  package{ 'zip':
    provider => gem,
    ensure => present
  }
    
  file { "${srv_elexis::config::jenkins_root}/jobs":
    ensure => directory,
   # require => Jenkins,
  }
  
  # we might maintain our jobs using Augeas XML-lenses, s.a. https://groups.google.com/forum/#!msg/puppet-users/ft04C3Szj8o/pC0e5tsZMX0J
  # But at the moment we take the lazy approach and just copy the config.xml file.
  # To ease downloading we create the helper shell/get_jobs.rb  
  define jenkins_job() {
    $job_root = "${srv_elexis::config::jenkins_root}/jobs"
    file { "$job_root/$title":
      ensure => directory,
      require => [ File["$job_root"], # Package['jenkins'],
      ],
    }
    
    file { "$job_root/$title/config.xml":
      mode    => 0644,
      ensure  => present,
      replace => false, # We don't want to override later local modifications!
      source  => "puppet:///modules/srv_elexis/jobs/$title/config.xml",
#      notify  => Service['jenkins'],
      require => File[ "$job_root/$title"],
    }
  }
  
  jenkins_job{[
    'Elexis-3.0-Base',
    'Elexis-3.0-Core',
    'Elexis-3.0-Jubula',
    'Elexis-3.0-MacOSX',
    'Elexis-3.0-MacOSX-jubula',
    'Elexis-3.0-Win7',
    'Elexis-3-3rdparty',
    'Elexis-3-derivate',
    ]:  
  }


}
