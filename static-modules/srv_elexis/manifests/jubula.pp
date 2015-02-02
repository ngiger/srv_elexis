  if (true) { # We just instal the two gem needed for jubula into the system
    notify{"rvm single user home is $srv_elexis::config::jenkins_root": }
    single_user_rvm::install { 'jenkins':
      home => "$srv_elexis::config::jenkins_root",
      require => [
                  # File["$home_rvm"],
#                  Package['jenkins'],
                  ],
    }
    single_user_rvm::install_ruby { 'ruby-1.9.3-p392': 
      user => 'jenkins',
      home => "$srv_elexis::config::jenkins_root",
#      require => Single_user_rvm::Install['jenkins'],
    }
  }
  package { ['xml-simple', 'rubyzip']:
    provider => gem,
    ensure => present,
  }
  
  $jubulaInstaller = "${srv_elexis::config::jenkins_root}/cache/installer-jubula_linux-gtk-x86_64.sh"
  file { "${srv_elexis::config::jenkins_root}/cache":
    ensure => directory,
#    require => Package[jenkins],
  }
  exec { "get_jubula":
    creates => $jubulaInstaller,
    command => '/usr/bin/curl --remote-name http://ftp.medelexis.ch/downloads_opensource/jubula/2.1/installer-jubula_linux-gtk-x86_64.sh',
    cwd     => "${srv_elexis::config::jenkins_root}/cache",
    require => Package['curl'],
  }
