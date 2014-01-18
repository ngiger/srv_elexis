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
class srv_elexis::wiki(
#  $elexis_wiki_server = "wiki.elexis.info" 
  $elexis_wiki_server = "srv.ngiger.dyndns.org" 
) inherits srv_elexis {
  
  $wiki_root = '/var/lib/mediawiki' # Debian default
  
  # We did not use the puppet module 
  #  * from souza because it is old and created havoc (imported images not displayed correctly, extension not correctly
  #  * from martasd because it failed because it wanted apache2-mpm-worker installed and I was unable to configure the puppet apache to fullfill this requres
  # Therefore going for our own.
  
  # missing sudo ln -s /usr/share/mediawiki/mw-config/ /var/lib/mediawiki//mw-configuration
  # setup
  # missing APC, XCache oder WinCache, e.g. sudo apt-get install php5-xcache
  # MySQL-DB angelegt elexis_wiki, elexis/elexisTest Verbindung abgelehnt
  #  ln -s /usr/share/mediawiki-extensions/base/NewestPages/ /var/lib/mediawiki//extensions
  #  ln -s /usr/share/mediawiki-extensions/base/LanguageSelector/ /var/lib/mediawiki//extensions
  # oder sudo mwenext NewestPages.php
  # oder sudo mwenext LanguageSelector.php
  # Added some content to mainpage
  # To import see http://www.mediawiki.org/wiki/Manual:Importing_XML_dumps
  # php /usr/share/mediawiki/maintenance/importDump.php  --conf LocalSettings.php dumpfile.xml.gz wikidb
  # After running importDump.php, you may want to run rebuildrecentchanges.php in order to update the content of your Special:Recentchanges page.$
  # php importImages.php ../path_to/images
  # TODO: php5-fpm fix fastcgi_pass unix:/var/run/php5-fpm.sock; ??
  # TODO: use php-apc instead of xcache
  # http://www.howtoforge.com/installing-nginx-with-php5-and-php-fpm-and-mysql-support-lemp-on-debian-wheezy-p2
  # https://github.com/kenpratt/wikipedia-client

  class { '::mysql::server':
    root_password    => 'foo',
    override_options => { 'mysqld' => { 'max_connections' => '1024' },
        'default_engine' => "innodb",
    }
  }
  class { 'mysql::client': }
  
  ensure_packages['php5-gd', 'mediawiki', 'mediawiki-extensions', 'mediawiki-extensions-collection', 'clamav', 'php-apc']
  # package{'imagemagick': ensure => absent, } # I want to use php5-gd
  
  file { '/etc/mediawiki/LocalSettings.php.soll':
    ensure => present,
    content => template("srv_elexis/LocalSettings.php.erb"),
  }
    
  # http://www.mediawiki.org/wiki/Manual:Running_MediaWiki_on_Debian_GNU/Linux
  # Als Logo für Elexis
  file { "$wiki_root/elexis_135.png":
    ensure => present,
    content => 'puppet:///modules/srv_elexis/elexis_135.png',
    require => Package['mediawiki'],
  }
  
  file { '/etc/nginx/sites-available/elexis_wiki':
    ensure => present,
    content => template("srv_elexis/nginx_elexis_wiki.erb"),
    require => Package['mediawiki'],
  }
  file { '/etc/nginx/sites-enabled/elexis_wiki':
    ensure  => link,
    target  => '/etc/nginx/sites-available/elexis_wiki',
    require => File['/etc/nginx/sites-available/elexis_wiki'],
  }

  if (false) {
    file { "$wiki_root/extensioNewestPages/":
      ensure  => link,
      target  => '/usr/share/mediawiki-extensions/base/NewestPages/',
      require => File['/etc/nginx/sites-available/elexis_wiki'],
    }
    file { "$wiki_root/LanguageSelector/":
      ensure  => link,
      target  => '/usr/share/mediawiki-extensions/base/LanguageSelector/',
      require => File['/etc/nginx/sites-available/elexis_wiki'],
    }
  }
    
  mysql::db { 'elexis_wiki':
    user     => 'elexis',
    password => 'elexisTest',
    host     => 'localhost',
    grant    => ['all'],
    # default charset is 'utf8',
  }
  
  class { 'mysql::server::backup':
    backupuser     => 'backup',
    backuppassword => 'elexisTest',
    backupdir      => '/opt/backups',
    backupdirgroup => 'backup',
    backuprotate   => '15',
  }

  logrotate::rule { 'mysql_wiki_dump':
    path         => '/opt/backups/mysql_wiki_dump.sql.bz2',
    olddir      => '/opt/backups/old',
    rotate_every => 'daily',
  }

  file { "/etc/cron.daily/wik_mysql_dump":
      ensure  => present,
      content => "#!/bin/bash
mkdir -p /opt/backups/old
mysqldump -u elexis -pelexisTest --opt --all-databases 2>/dev/null | bzcat -zc > /opt/backups/mysql_wiki_dump.sql.bz2
chown backup /opt/backups/mysql_wiki_dump.sql.bz2
",
      mode => 0744,
  }
}