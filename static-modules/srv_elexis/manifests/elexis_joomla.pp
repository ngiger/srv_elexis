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
# deb http://packages.dotdeb.org wheezy all
class srv_elexis::elexis_joomla(
  $elexis_joomla_server = ""
) inherits srv_elexis {
  
  $joomla_root = '/home/www/joomla'
  
  include srv_elexis::mysql

  $joomla_source = "http://joomlacode.org/gf/download/frsrelease/19239/158104/Joomla_3.2.3-Stable-Full_Package.zip"
  $joomla_dest   = '/opt/Joomla_3.2.3-Stable-Full_Package.zip'
  if (false) {
  include vsftpd
  }
  else {
    class { 'vsftpd':
      anonymous_enable  => 'YES',
      write_enable      => 'no',
      ftpd_banner       => 'Elexis Joomla access for migrations',
      chroot_local_user => 'NO',
    }
    file { '/etc/vsftpd.user_list':
      ensure => present,
      content => "# empty",
    }
  }
  exec {"$joomla_dest":
    creates => "$joomla_dest",
    command => "/usr/bin/wget --output-document=$joomla_dest $joomla_source",
    require => Package['wget'],
  }

  file{$joomla_root:
    ensure => directory,
    require => [File['/home/www']],
    owner => 'www-data',
    group => 'www-data',
  }

  exec {"$joomla_root/index.php":
    creates => "$joomla_root/index.php",
    command => "/usr/bin/unzip -q $joomla_dest",
    require => [File[$joomla_root], Package['unzip']],
    cwd     => "$joomla_root",
    user    => 'www-data',
  }
  # unzipped manually the backup sent by gerry and loaded it into the database with
  # mysql -u elexis --password=elexisTest elexis_joomla </vagrant/elexis.sql
  # now mysql -u elexis --password=elexisTest elexis_joomla_3_2 </vagrant/elexis.sql
  # works and show configuration
# You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'TYPE=MyISAM CHARACTER SET `utf8`' at line 29 SQL=CREATE TABLE `jos_banner` ( `bid` int(11) NOT NULL auto_increment, `cid` int(11) NOT NULL default '0', `type` varchar(30) NOT NULL default 'banner', `name` varchar(255) NOT NULL default '', `alias` varchar(255) NOT NULL default '', `imptotal` int(11) NOT NULL default '0', `impmade` int(11) NOT NULL default '0', `clicks` int(11) NOT NULL default '0', `imageurl` varchar(100) NOT NULL default '', `clickurl` varchar(200) NOT NULL default '', `date` datetime default NULL, `showBanner` tinyint(1) NOT NULL default '0', `checked_out` tinyint(1) NOT NULL default '0', `checked_out_time` datetime NOT NULL default '0000-00-00 00:00:00', `editor` varchar(50) default NULL, `custombannercode` text, `catid` INTEGER UNSIGNED NOT NULL DEFAULT 0, `description` TEXT NOT NULL DEFAULT '', `sticky` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0, `ordering` INTEGER NOT NULL DEFAULT 0, `publish_up` datetime NOT NULL default '0000-00-00 00:00:00', `publish_down` datetime NOT NULL default '0000-00-00 00:00:00', `tags` TEXT NOT NULL DEFAULT '', `params` TEXT NOT NULL DEFAULT '', PRIMARY KEY (`bid`), KEY `viewbanner` (`showBanner`), INDEX `idx_banner_catid`(`catid`) ) TYPE=MyISAM CHARACTER SET `utf8`
  ensure_packages(['php5-gd', 'nginx', 'wget','tar', 'php5-fpm'])
  
  file { '/etc/nginx/sites-available/elexis_joomla':
    ensure => present,
    content => template("srv_elexis/nginx_elexis_joomla.erb"),
    require => Package['nginx'],
  }
  file { '/etc/nginx/sites-enabled/elexis_joomla':
    ensure  => link,
    target  => '/etc/nginx/sites-available/elexis_joomla',
    require => File['/etc/nginx/sites-available/elexis_joomla'],
  }

  mysql::db { 'elexis_joomla':
    user     => 'elexis',
    password => 'elexisTest',
    host     => 'localhost',
    grant    => ['all'],
    # default charset is 'utf8',
  }
  mysql::db { 'elexis_joomla_3_2':
    user     => 'elexis',
    password => 'elexisTest',
    host     => 'localhost',
    grant    => ['all'],
    # default charset is 'utf8',
  }

  logrotate::rule { 'mysql_joomla_dump':
    path         => '/opt/backups/mysql_joomla_dump.sql.bz2',
    olddir      => '/opt/backups/old',
    rotate_every => 'daily',
  }

  file { "/etc/cron.daily/joomla_mysql_dump":
      ensure  => present,
      content => "#!/bin/bash
mkdir -p /opt/backups/old
mysqldump -u elexis -pelexisTest --opt --all-databases 2>/dev/null | bzcat -zc > /opt/backups/mysql_joomla_dump.sql.bz2
chown backup /opt/backups/mysql_joomla_dump.sql.bz2
",
      mode => '0744',
  }
}