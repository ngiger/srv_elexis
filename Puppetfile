forge "http://forge.puppetlabs.com"
# Configuration for librarian-puppet. For example:
# 
mod "jenkins",
#  :git => "git://github.com/jenkinsci/puppet-jenkins.git"
  :git => 'https://github.com/ngiger/puppet-jenkins.git' # with a patch from me to support installation into JENKINS_HOME
#  :path => './static-modules/puppet-jenkins' # for testing the patch

#mod 'martasd/mediawiki'
  # :git => 'git://github.com/martasd/puppet-mediawiki.git'
#   :path => './static-modules/puppet-mediawiki'
# dependency 'puppetlabs/apache', '>= 0.4.0'
# dependency 'puppetlabs/mysql', '>= 0.5.0'
# dependency 'saz/memcached', '>= 2.0.0'
# dependency 'puppetlabs/stdlib', '>= 3.0.0' 

mod 'carlasouza/mediawiki'
mod "puppetlabs/mysql", :git => 'https://github.com/puppetlabs/puppetlabs-mysql.git'
mod 'rodjek/logrotate'

# mod "puppetlabs/apache"
mod "saz/memcached"
# mod "puppetlabs/stdlib"

mod "apt",
  :git => "git://github.com/puppetlabs/puppetlabs-apt.git"

# mod "stdlib",
#  :git => "git://github.com/puppetlabs/puppetlabs-stdlib.git"

mod 'single_user_rvm',
  :git => 'https://github.com/eirc/puppet-single_user_rvm.git' # with a patch from me
#  :git => 'https://github.com/ngiger/puppet-single_user_rvm.git' # with a patch from me
#  :path => './static-modules/puppet-single_user_rvm' # for testing the patch
  
mod 'srv_elexis',     :path => './static-modules/srv_elexis'


# Lokale, nicht echte Module von mir, eventuell von elexis-vagrant holen
# mod 'apache',     :path => './static-modules/apache'
#mod 'cockpit',    :path => './static-modules/cockpit'
#mod 'eclipse',    :path => './static-modules/eclipse'
#mod 'elexis',     :path => './static-modules/elexis'
#mod 'java',       :path => './static-modules/java'
#mod 'jubula',     :path => './static-modules/jubula'
#mod 'kde',        :path => './static-modules/kde'
#mod 'ntp_demo',   :path => './static-modules/ntp_demo'
#mod 'util',       :path => './static-modules/util'
