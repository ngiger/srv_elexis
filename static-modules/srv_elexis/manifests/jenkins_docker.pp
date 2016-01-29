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

class srv_elexis::jenkins_docker(
  $elexis_releng_dir = '/opt/elexis-releng',
                  ) inherits srv_elexis {

  ssh_keygen { 'jenkins': }
  include 'docker_compose'
  # runs then under http://srv.ngiger.dyndns.org:8081/
  vcsrepo {"$elexis_releng_dir":
    ensure   => present,
    source   => 'https://github.com/ngiger/elexis-releng.git',
    provider => 'git',
    require => File['/home/jenkins/.ssh'],
  }
  Vcsrepo[$elexis_releng_dir] ~>  Exec['build_elexis_releng']
  file{'/home/jenkins/.ssh':
    ensure => directory,
    owner => 'jenkins',
    group => 'jenkins',
    mode => '0700',
    require => User['jenkins'],
  }

  file{"$elexis_releng_dir/jenkins/jenkins.pub":
    source => '/home/jenkins/.ssh/id_rsa.pub',
    require => [Ssh_keygen['jenkins']],
  }
  file{"$elexis_releng_dir/jenkins/jenkins":
    source => '/home/jenkins/.ssh/id_rsa',
    require => [Ssh_keygen['jenkins']],
  }
  exec{'build_elexis_releng':
    command => "/usr/local/bin/docker-compose build",
    require => [ Vcsrepo[$elexis_releng_dir],
      Class['docker',  'docker_compose'],
      File["$elexis_releng_dir/jenkins/jenkins", "$elexis_releng_dir/jenkins/jenkins.pub"],
    ],
    cwd => "$elexis_releng_dir/jenkins",
    timeout     => 1800,
#    creates => '/usr/local/bin/cleanup_snapshots.rb',
  }
  exec{'start_elexis_releng':
    command => "/usr/local/bin/docker-compose up -d jenkinstest",
    require => Exec['build_elexis_releng'],
    cwd => "$elexis_releng_dir/jenkins",
#    creates => '/usr/local/bin/cleanup_snapshots.rb',
  }

}
