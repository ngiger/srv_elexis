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

  $wiki_root = '/home/docker-data-containers'
  exec { 'docker-compose-wiki':
    cwd => "$srv_elexis::docker_files/srv.elexis.info",
    command => "/usr/local/bin/docker-compose up -d",
    require => [ Vcsrepo[$srv_elexis::docker_files],
      Class['docker_compose']
      ],
    unless => "/usr/bin/docker ps | /bin/grep srvelexisinfo_wikidb_1",
  }

  docker::run { 'wiki':
    image => 'wiki',
    use_name        => true,
    restart_service => true,
    privileged      => false,
    pull_on_start   => false,
    before_stop     => 'echo "So Long, and Thanks for All the Fish"',
    # username => 'wiki',
    ports  => ['8080:8080', '50000:50000'],
    volumes => [
      "$wiki_root:/var/wiki_home",
    ],
  }

  # http://www.mediawiki.org/wiki/Extension:DeleteHistory
  # BlockAndNuke
  # Ruby https://github.com/wikimedia/mediawiki-ruby-api (no longer in active development)
  #      https://github.com/jpatokal/mediawiki-gateway
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

  file { "/etc/nginx/sites-enabled/elexis_wiki":
    ensure => absent,
  }
  file { "/etc/nginx/sites-enabledwiki.$::domain":
    ensure => absent,
  }
  file { "/etc/nginx/sites-enabled/wiki.$::domain":
    ensure => present,
    require => File["/etc/nginx/sites-enabledwiki.$::domain"],
    content => # template("srv_elexis/nginx_elexis_wiki.erb"),
    "# $::srv_elexis::config::managed_note
server {
  listen 80;
  server_name  wiki.elexis.info;
  index index.html index.htm index.php;
  root /srv/mediawiki;

  allow all;
  location / {
    proxy_pass              http://localhost:8888;

  }
}
",
  }

  file { "$wiki_root":
    ensure  => directory,
    owner => 'www-data',
  }

  file { "$wiki_root/config/LocalSettings.php.soll":
    ensure => present,
    owner => 'www-data',
    content => template("srv_elexis/LocalSettings.php.erb"),
    require => File["$wiki_root/config"],
  }

  file { '/var/www/mediawiki':
    ensure  => link,
    target  => $wiki_root,
    owner => 'www-data',
    require => File[$wiki_root],
  }

  file { "$wiki_root/images":
    ensure => directory,
    owner => 'www-data',
    require => File[$wiki_root],
  }

  file { "$wiki_root/config":
    ensure => directory,
    owner => 'www-data',
    require => File[$wiki_root],
  }

  # http://www.mediawiki.org/wiki/Manual:Running_MediaWiki_on_Debian_GNU/Linux
  # Als Logo für Elexis
  file { "$wiki_root/elexis_135.png":
    ensure => present,
    content => 'puppet:///modules/srv_elexis/elexis_135.png',
  }

}