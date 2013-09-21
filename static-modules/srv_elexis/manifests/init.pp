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

class srv_elexis {
   
  require srv_elexis::config
  
  $managed_note = 'Managed by puppet via project repo https://github.com/ngiger/srv_elexis)'
  
  ensure_packages['git', 'unzip', 'dlocate', 'mlocate', 'htop', 'curl', 'etckeeper', 'unattended-upgrades', 'mosh',
                  'ntpdate', 'anacron', 'maven', 'ant', 'ant-contrib']
  
  if ($hostname == 'srv') {
    class {'jenkins': 
      lts => 1, #  we want the long term support version
      config_hash => { 'HTTP_PORT' => { 'value' => '8080' },  
        'dummy' => { 'value' => "# $managed_note" }, 
        'AJP_PORT' => { 'value' => "-1" }, 
        'PREFIX'   => { 'value' => '/jenkins' },
        'JENKINS_ARGS' => { 'value' => '--webroot=/var/cache/jenkins/war --httpPort=$HTTP_PORT --prefix=$PREFIX --ajp13Port=$AJP_PORT' },
      }  
    }
    jenkins::plugin {[
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
      'subversion',
      'thinBackup',
      'timestamper',
      'xvnc',
      ]: 
    }
  } 
  # we have credentials 1.3.1
  jenkins::plugin {'ssh-credentials':   version => "1.1"} 
  jenkins::plugin {'ssh-slaves':   version => "1.1"}
    
  # notify { "jenkins_root ist $srv_elexis::config::jenkins_root":}
  user{'jenkins':
    ensure => present,
    home   => "$srv_elexis::config::jenkins_root",
  }
  
  single_user_rvm::install { 'jenkins':
    home => "$srv_elexis::config::jenkins_root",
    require => [
                # File["$home_rvm"],
                Package['jenkins'], 
                ],
  }
  single_user_rvm::install_ruby { 'ruby-1.9.3-p392': 
    user => 'jenkins',
    home => "$srv_elexis::config::jenkins_root",
    require => Single_user_rvm::Install['jenkins'],
  }
  
  file {'/home/jenkins/.gitconfig':
  content => "# $managed_note
[user]
        email = niklaus.giger@member.fsf.org
        user = Niklaus Giger
[credential]
        helper = cache --timeout=3600
# Set the cache to timeout after 1 hour (setting is in seconds)
",
    mode => 0644,
    }
  
  File {
    owner => 'jenkins',
    group => 'jenkins',
  }
  $jenkin_backup_root = '/home/jenkins'
  file { "$jenkin_backup_root":
    ensure => directory,
    require => Package['jenkins'],
  }

  file { "$jenkin_backup_root/backup":
    ensure => directory,
    require => File["$jenkin_backup_root"],
  }
  file { "$jenkins_root/thinBackup.xml":
    ensure => present,
    source => 'puppet:///modules/srv_elexis/thinBackup.xml',
    require => File["$jenkin_backup_root/backup"],
    notify => Service['jenkins'],
  }
  
  # forward srv.elexis.info/jenkins/ to the real jenkins
  ensure_packages['nginx']
  file {          "/etc/nginx/sites-enabled/$fqdn":
    target => "/etc/nginx/sites-available/$fqdn",
    ensure => link,
    owner => root,
    group => root,
  }
  file { "/etc/nginx/sites-available/$fqdn":
  content => "# $managed_note
server {
  listen 80;
  server_name  $fqdn;
  allow all;

  location /jenkins/ {
    proxy_pass              http://localhost:8080;
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_connect_timeout   150;
    proxy_send_timeout      100;
    proxy_read_timeout      100;
    proxy_buffers           4 32k;
    client_max_body_size    8m;
    client_body_buffer_size 128k;

  }
}",  require => Package['nginx'],
    owner => root,
    group => root,
  }
  service{'nginx':
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    provider => 'debian',
    require => Package['nginx'],
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
  
  $jubulaInstaller = '/var/cache/installer-jubula_linux-gtk-x86_64.sh'
  exec { "get_jubula":
    creates => $jubulaInstaller,
    command => '/usr/bin/curl --remote-name http://ftp.medelexis.ch/downloads_opensource/jubula/2.1/installer-jubula_linux-gtk-x86_64.sh',
    cwd     => '/var/cache',
    require => Package['curl'],
  }
}
