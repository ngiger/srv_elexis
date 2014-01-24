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

class srv_elexis {
   
  if ($fqdn == 'srv.elexis.info') {
    class {'srv_elexis::config': jenkins_root => '/home/jenkins', }
  } else {
    class {'srv_elexis::config': jenkins_root => '/var/lib/jenkins', }
  }
  include srv_elexis::backup
  
  $managed_note = 'Managed by puppet via project repo https://github.com/ngiger/srv_elexis'
  
  ensure_packages['git', 'unzip', 'dlocate', 'mlocate', 'htop', 'curl', 'etckeeper', 'unattended-upgrades', 'fish', 'mosh',
                  'ntpdate', 'anacron', 'maven', 'ant', 'ant-contrib', 'sudo', 'screen', 'nginx', 'postgresql', 'wget']
  
  if ($hostname == 'srv') {
    file{["$srv_elexis::config::jenkins_root/tmp", "$srv_elexis::config::jenkins_root/log"]:
      ensure => directory, owner => 'jenkins'
      
    }
    class {'jenkins':
      jenkins_home => "$srv_elexis::config::jenkins_root",
      lts => 1, #  we want the long term support version
      config_hash => { 'HTTP_PORT' => { 'value' => '8080' },  
        'dummy' => { 'value' => "# $managed_note" }, 
        'AJP_PORT' => { 'value' => "-1" }, 
        'PREFIX'   => { 'value' => '/jenkins' },
        # not necessary for the moment -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/jenkins/memory.dump 
        'JAVA_ARGS' => { 'value' => "-Djava.io.tmpdir=$srv_elexis::config::jenkins_root/tmp -Djava.awt.headless=true -Xrs -Xmx1024m -XX:PermSize=512m -XX:MaxPermSize=2048m " },
        'JENKINS_ARGS' => { 'value' => '--webroot=/var/cache/jenkins/war --httpPort=$HTTP_PORT --prefix=$PREFIX --ajp13Port=$AJP_PORT' },
      }  
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
#      'role-stratey', # Cannot be installed via puppet!
      'subversion',
      'thinBackup',
      'timestamper',
      'xvnc',
      ]
    jenkins::plugin {$jenkins_plugins:,
    }
  } 
  
  define install_config() {
    file { "${srv_elexis::config::jenkins_root}/${title}.xml":
      source  => "puppet:///modules/srv_elexis/config.xml",
      require => [ Package['jenkins'], ],
      notify => Service['jenkins'],
    }    
  }
  install_config{"config": }
  
  # we have credentials 1.3.1
  jenkins::plugin {'ssh-credentials':   version => "1.1"} 
  jenkins::plugin {'ssh-slaves':   version => "1.1"}
    
  # notify { "jenkins_root ist $srv_elexis::config::jenkins_root":}
  ensure_resource('user', 'jenkins', {
    ensure => present,
    home   => "$srv_elexis::config::jenkins_root",
  })
  
  exec{'/usr/local/bin/cleanup_snapshots.rb':
    command => "/usr/bin/wget https://raw2.github.com/elexis/elexis-3-core/f1a114847b8753ef5b179712be27d25783065e8c/ch.elexis.core.p2site/cleanup_snapshots.rb && /bin/chmod +x cleanup_snapshots.rb",
    require => Package['wget'],
    cwd => '/usr/local/bin/',
    creates => '/usr/local/bin/cleanup_snapshots.rb',
  }
  
  cron { 'cleanup_snapshots':
    ensure  => $ensure,
    command => 'P2_ROOT=/home/jenkins/downloads /usr/local/bin/cleanup_snapshots.rb &> /var/log/cleanup_snapshots.log',
    user    => 'root',
    hour    => 1,
    minute  => 5,
    require => Exec['/usr/local/bin/cleanup_snapshots.rb'],
  }
  
  file {'/etc/gitconfig':
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
  if ("$jenkin_backup_root" != "$srv_elexis::config::jenkins_root") {
    file { "$jenkin_backup_root":
      ensure => directory,
      require => Package['jenkins'],
    }
  }

  file { "$jenkin_backup_root/backup":
    ensure => directory,
    require => File["$jenkin_backup_root"],
  }
  
  file { "$srv_elexis::config::jenkins_root/thinBackup.xml":
    ensure => present,
    source => 'puppet:///modules/srv_elexis/thinBackup.xml',
    require => File["$jenkin_backup_root/backup"],
    notify => Service['jenkins'],
  }
  
  # forward srv.elexis.info/jenkins/ to the real jenkins
  ensure_packages['nginx', 'openssl']
  file {          "/etc/nginx/sites-enabled/$fqdn":
    target => "/etc/nginx/sites-available/$fqdn",
    ensure => link,
    owner => root,
    group => root,
  }

  file {"/etc/nginx/ssl":
    ensure => directory,
    owner => root,
    group => root,
    require => Package['nginx'],
  }

  exec {'/etc/nginx/ssl/srv.elexis.info.cert':
    creates => "/etc/nginx/ssl/srv.elexis.info.cert",
    command => '/usr/bin/openssl req -days 1830 -subj "/C=CH/ST=Glarus/L=Mollis/O=Elexis Opensource community/CN=srv.elexis.info/EM=niklaus.giger@member.fsf.org" -nodes -new -x509  -keyout srv.elexis.info.key -out srv.elexis.info.cert',
    cwd     => '/etc/nginx/ssl',
    require => File['/etc/nginx/ssl'],
    notify => Service['nginx'],
  }
  
  file { "/etc/nginx/sites-available/$fqdn":
  content => "# $managed_note
server {
  listen 443;
  server_name  $fqdn;
  allow all;
  ssl on;
  ssl_certificate_key /etc/nginx/ssl/srv.elexis.info.key;
  ssl_certificate     /etc/nginx/ssl/srv.elexis.info.cert;

  location /jenkins/ {
    proxy_pass              http://localhost:8080;
    proxy_connect_timeout   150;
    proxy_send_timeout      100;
    proxy_read_timeout      100;
    proxy_buffers           4 32k;
    client_max_body_size    8m;
    client_body_buffer_size 128k;
  }
}
",  require => [ Package['nginx'], Exec['/etc/nginx/ssl/srv.elexis.info.cert'], ],
    owner => root,
    group => root,
    notify => Service['nginx'],
  }
  file {          "/etc/nginx/sites-enabled/download.elexis.info":
    target => "/etc/nginx/sites-available/download.elexis.info",
    ensure => link,
    owner => root,
    group => root,
  }
  file { "/etc/nginx/sites-available/download.elexis.info":
  content => "# $managed_note
server {
  listen 80;
  server_name  download.elexis.info;
  root /home/jenkins/downloads;
  autoindex on;
  allow all;
}
",  require => Package['nginx'],
    owner => root,
    group => root,
    notify => Service['nginx'],
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
  
}
