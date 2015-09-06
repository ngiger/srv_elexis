# Setup a jenkins-slave to be able to run Jubula tests on the local machine
# We use a password-less ssh login
# kate: replace-tabs on; indent-width 2; indent-mode cstyle; syntax ruby

class srv_elexis::vnc_client  inherits srv_elexis {
  
  # Parts copied from elexis-vagrant
  define enable_vnc_client(
    $home = "/home/${title}"
  ) {
    notify{"enab $user $home $title": }
    $user = $title
    file { "${home}/xstartup":
      ensure => present,
      source => 'puppet:///modules/srv_elexis/xstartup', # Copy from jubula-elexis project
    }

    if (false) {
    $passwdScript = "${home}/set_vncpasswd.exp"
    file { $passwdScript:
      ensure => true,
      source => 'puppet:///modules/srv_elexis/set_vncpasswd.exp',
      mode => 0755,
    }
    
    if !defined(Package['expect']) { package{ 'expect': ensure => present, } }
    exec { $passwdScript:
      require => [
#          User[$s_user], 
          File[$passwdScript],  
          Package['xvfb','expect']
                 ],
      command => "sudo -Hu $user $passwdScript",
      creates => "${home}/.vnc/passwd",
      path    => '/usr/bin:/bin',
    }
}
  }
  enable_vnc_client{ 'jenkins': # ensure that the user jenkins can run Jubula as a vnc-client
    home => "$srv_elexis::config::jenkins_root"
    
  } 
  # we need
  # * an X-Server (vnc4server)
  # * some method to create a snapshot (imagemagick)
  # * a X-Window manager (fvwm)
  package { ['imagemagick', 'fvwm', 'xvfb']: ensure => installed, }

  # needed ia32-libs-gtk
  # eclipse ??
  # 
# TODO: Jubula needs a 32-bit Java (and a 32-bit Elexis)
# TODO: 32-bit java, eg. sudo apt-get install openjdk-6-jdk:i386 openjdk-6-jre-headless:i386
}
