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

    $passwdScript = "${home}/set_vncpasswd.exp"
    file { $passwdScript:
      ensure => present,
      source => 'puppet:///modules/srv_elexis/set_vncpasswd.exp',
      mode => 0755,
    }
    
    if !defined(Package['expect']) { package{ 'expect': ensure => present, } }
    exec { $passwdScript:
      require => [
#          User[$s_user], 
          File[$passwdScript],  
          Package['vnc4server','expect']
                 ],
      command => "sudo -Hu $user $passwdScript",
      creates => "${home}/.vnc/passwd",
      path    => '/usr/bin:/bin',
    }
  }
  enable_vnc_client{ 'jenkins': # ensure that the user jenkins can run Jubula as a vnc-client
    home => "$srv_elexis::config::jenkins_root"
    
  } 
  # we need
  # * an X-Server (vnc4server)
  # * some method to create a snapshot (imagemagick)
  # * a X-Window manager (fvwm)
  package { ['imagemagick', 'fvwm', 'vnc4server']: ensure => installed, }

}
