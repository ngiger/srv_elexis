# vi: set ft=ruby :
# kate: replace-tabs on; indent-width 2; indent-mode cstyle; syntax ruby
# == Class: srv_elexis::backup
#
# Allows remote backup of srv_elexis
#
# === Parameters
#
# Document parameters here.
#
# None
#
# === Variables
#
#
# === Examples
#
#  class { srv_elexis::backup:
#  }
#
# === Authors
#
# Niklaus Giger <niklaus.giger@member.fsf.org>
#
# === Copyright
#
# Copyright 2014 Niklaus Giger <niklaus.giger@member.fsf.org>
#
class srv_elexis::backup(
) inherits srv_elexis {

  ensure_packages['etckeeper']
  
  file { '/etc/.git':
    ensure => directory,
    owner  => root,
    group  => root,
    recurse => true,
    require => Package['etckeeper'],
  }

  ensure_resource('user', ['marco', 'niklaus', 'artikelstamm',], {'ensure' => 'present' })

  user{ 'backup':
    groups => ['marco', 'niklaus', 'www-data', 'jenkins', 'artikelstamm'],
    shell  => '/bin/bash', # We must change nologin -> sh or bash to allow rsnapshot access via rsync
  }
}