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

class srv_elexis (
  $docker_files = '/opt/elexis-dockerfiles',
  $jenkins_home = '/home/jenkins'
) {

  include apt
  include apt::backports
  include srv_elexis::config
  ensure_packages(['unzip', 'dlocate', 'mlocate', 'htop', 'curl', 'etckeeper', 'unattended-upgrades', 'mosh',
                  'ntpdate', 'anacron', 'maven', 'ant', 'ant-contrib', 'sudo', 'screen', 'postgresql', 'wget'])

  ensure_resource('user', 'jenkins', { 'ensure' => 'present'} )

  apt::pin { 'backports_fish':
    packages => 'fish',
    priority => 200,
#    release  => 'main',
  }
  package{'fish':
    require => Apt::Pin['backports_fish'],
  }
  # Use docker.io from Debian
  # as I have problems with docker-engine on srv.elexis.info (but not on my Virtual Box)
 # file {'/usr/bin/docker.io':   ensure => link,    target => '/usr/bin/docker',  }
 class { 'docker':
      docker_users => ['niklaus', 'www-data'],
      tcp_bind    => 'tcp://0.0.0.0:4243',
      socket_bind => 'unix:///var/run/docker.sock',
    }
  package{ ['docker.io', 'docker-compose']:
    ensure => absent
  }

  file {'/etc/gitconfig':
  content => "# $::srv_elexis::config::managed_note
[user]
        email = niklaus.giger@member.fsf.org
        user = Niklaus Giger
[credential]
        helper = cache --timeout=3600
# Set the cache to timeout after 1 hour (setting is in seconds)
",
    mode => '0644',
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

  vcsrepo {$docker_files:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/ngiger/elexis-dockerfiles.git',
    require => User['jenkins'],
  }

  file {'/home/www' :
    ensure => directory,
    owner => 'www-data',
  }

}
