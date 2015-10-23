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

class srv_elexis::jenkins_ci inherits srv_elexis {

  # runs then under http://srv.ngiger.dyndns.org:8080/

  file{$srv_elexis::docker_files:
    ensure => directory,
  }
  $dump_sha = "/home/jenkins/jenkin_config_dump.sha"

  class { 'jenkins':
    localstatedir  => '/home/jenkins',
    user           => '1000', # The docker image uses UID/GID 1000
    service_ensure => false,
    service_enable => true,
    install_java   => false,
    configure_firewall => false,
    manage_user        => false,
  }
   exec { "enforce /home/jenkins permissions":
    command => "/bin/chown -R 1000:1000 /home/jenkins",
    subscribe => File["/home/jenkins"],
  }

  # The name of the plugin can be found here https://updates.jenkins-ci.org/download/plugins/
  $jenkins_plugins = [
    'build-timeout',
    'compact-columns',
    'console-column-plugin',
    'copy-to-slave',
    'credentials',
    'disk-usage',
    'extra-columns',
    'git',
    'git-client',
    'git-parameter',
    'github',
    'github-api',
    'javadoc',
    'jobConfigHistory',
    'locks-and-latches',
    'maven-plugin',
    'mercurial',
    'redmine',
    'ruby',
    'rvm',
    'rake',
    'role-stratey', # Cannot be installed via puppet!
    'ssh-credentials',
    'ssh-slaves',
    'subversion',
    'thinBackup',
    'timestamper',
    'xvfb',
    ]

  jenkins::plugin {$jenkins_plugins:, # go into /var/lib/jenkins
    create_user => false,
    # notify => Exec["enforce /home/jenkins permissions"],
  }

  file{"/home/jenkins/remove_security.rb":
    ensure => present,
    source  => "puppet:///modules/srv_elexis/jenkins/remove_security.rb",
    notify =>  Docker::Image['jenkins'],
    require => [File[$srv_elexis::docker_files], Vcsrepo[$srv_elexis::docker_files],
      ],
  }

  docker::image { 'jenkins':
    docker_dir => $srv_elexis::docker_files,
    require => Vcsrepo[$srv_elexis::docker_files],
    notify =>  Docker::Run['jenkins'],
  }

  Vcsrepo[$srv_elexis::docker_files] ~> Docker::Image['jenkins']

  docker::run { 'jenkins':
    image => 'jenkins',
    use_name        => true,
    restart_service => true,
    privileged      => false,
    pull_on_start   => false,
    before_stop     => 'echo "So Long, and Thanks for All the Fish"',
    # username => 'jenkins',
    ports  => ['8080:8080', '50000:50000'],
    volumes => [
      "$srv_elexis::jenkins_home:/var/jenkins_home",
    ],
  }
  # docker run -p 8080:8080 -p 50000:50000 -v /your/home:/var/jenkins_home jenkins
  # das lief, nach einem chown -R vagrant:vagrant /home/jenkins
  # docker run -p 8080:8080 -p 50000:50000 -v /home/jenkins:/var/jenkins_home --name jenkins --user 1000 --rm jenkins
  # es fehlen noch die git credentials, Zu finden via root@srv.elexis.info:/home/jenkins/credentials.xml
  # credentials für elexis-core ssh fin
  # /home/jenkins/.ssh/elexis_core
  # -rw------- 1 jenkins jenkins 1679 Feb 20  2014 /home/jenkins/.ssh/elexis_core
  # -rw-r--r-- 1 jenkins jenkins  393 Feb 20  2014 /home/jenkins/.ssh/elexis_core.pub
  # cat /home/jenkins/.ssh/elexis_core.pub
  # ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCybcoqgqQM31PDMxZISpxIg1mG9m022uOiL28A6Obh4JjZUYNtbVTOCX7fES2VhunK2JZ1+kXso0ZM7s18PA1ML81GhHs8mcBNnOh9CPHlp9y2s8z7022Ej8cKpNDz7nwGFlhMS3b05n6njCIIV6C1cq/Q00+ssZRc/EeCQCFCznd8q4rQIbub16UvUNMY577BZamiLMswLSAOUAKenBijqfUhbvW5i1xa8pWJdkSEHqD3sl99U9ebFzfj9dyQftK7RL7GIaV4seBZJRFpj5GknwNNNNeBCvyW1I+bmo8QkT4mcb/3GJPXxJR3rBmlZKMM6j1Qda5ocpLus2h8ofWx jenkins@srv

  # This will store the jenkins data in /your/home on the host. Ensure that /your/home is accessible by the jenkins user in container (jenkins user - uid 1000) or use -u some_other_user parameter with docker run.

  include 'postgresql::server'
  postgresql::server::db {  [ 'tests', 'unittest']:
    user     => 'elexis',
    password => postgresql_password('mydatabaseuser', 'elexisTest'),
  }

  $cleanup_origin = 'https://raw.githubusercontent.com/elexis/elexis-3-core/release/3.0.15/ch.elexis.core.p2site/cleanup_snapshots.rb'
  exec{'/usr/local/bin/cleanup_snapshots.rb':
    # https://raw.githubusercontent.com/elexis/elexis-3-core/master/ch.elexis.core.p2site/cleanup_snapshots.rb
    command => "/usr/bin/wget $cleanup_origin && /bin/chmod +x cleanup_snapshots.rb",
    require => Package['wget'],
    cwd => '/usr/local/bin/',
    creates => '/usr/local/bin/cleanup_snapshots.rb',
  }

  File {
    owner => 'jenkins',
  }
  $jenkin_backup_root = '/home/jenkins'

  file { "$jenkin_backup_root/.m2":
    ensure => directory,
    require => File[$jenkin_backup_root]
  }
    file { "$jenkins_home/.m2/settings.xml":
      require => [File["$jenkin_backup_root/.m2"],],
      content => '<?xml version="1.0" encoding="UTF-8"?>
<!-- $::srv_elexis::config::managed_note -->
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <activeProfiles>
    <activeProfile>elexis</activeProfile>
  </activeProfiles>
  <profiles>
    <profile>
      <id>elexis</id>
      <properties>
        <tycho.localArtifacts>ignore</tycho.localArtifacts>
        <!-- true for people how have a MySQL and PostgreSQL database unittest accessible for user elexis with password elexisTest -->
        <elexis.run.dbtests>true</elexis.run.dbtests>
      </properties>
    </profile>
  </profiles>
</settings>
',
    }


  file { "$jenkin_backup_root/backup":
    ensure => directory,
    require => File["$jenkin_backup_root"],
  }

  file { "$jenkins_home/thinBackup.xml":
    ensure => present,
    content => template('srv_elexis/thinBackup.xml'),
    require => File["$jenkin_backup_root/backup"],
  }

  file {'/etc/cron.daily/daily_jenkins_cleanup':
    content => '#!/bin/bash
logger "$0 starting" `df -h /tmp`
rm -rf /tmp/config*
rm -rf /tmp/tycho*
rm -rf /tmp/elexis*
rm -rf /tmp/abc*
rm -rf /tmp/ausgabe*
logger "$0 finished" `df -h /tmp`
'
  }

  if (false) { # tried to automate loading a dump
    exec{$dump_sha:
      cwd => "/home/jenkins",
      command => "/bin/tar -xvf ${docker_files}/jenkin_config_dump.tar.gz && /bin/chown -R 1000:1000 /home/jenkins && /usr/bin/ruby remove_security.rb && /usr/bin/sha512sum ${docker_files}/jenkin_config_dump.tar.gz > /home/jenkins/jenkin_config_dump.sha",
      creates => $dump_sha,
      require => File["/home/jenkins/remove_security.rb"],
      notify =>  Docker::Image['jenkins'],
    }
    file{"${docker_files}/Dockerfile":
      ensure => present,
      source  => "puppet:///modules/srv_elexis/jenkins/Dockerfile",
      notify =>  Docker::Image['jenkins'],
      require => [File[$srv_elexis::docker_files],
        Exec[$dump_sha],
        ],
    }
  }
}
