# -*- mode: ruby -*-
# vi: set ft=ruby :

#------------------------------------------------------------------------------------------------------------
# Some simple customization below
#------------------------------------------------------------------------------------------------------------
boxId = 'Elexis-Wheezy-amd64-20130510' # Wheezy was released on May 4th, 2013
# See http://www.debian.org/News/2013/20130504
private = "/opt/src/veewee-elexis/#{boxId}.box"
boxUrl = File.exists?(private) ? private : "http://ngiger.dyndns.org/downloads/#{boxId}.box"
puts "Using boxUrl #{boxUrl}"

bridgedNetworkAdapter = "eth0" # adapt it to your liking, e.g. on MacOSX it might 

# Allows you to select the VMs to boot
# systemsToBoot = [ :fest, :test ]
systemsToBoot = [ :srv]

# Patch the next lines if you have more than one elexis-vagrant running in your network
firstPort       = 52000   

#------------------------------------------------------------------------------------------------------------
# End of simple customization
#------------------------------------------------------------------------------------------------------------
# All Vagrant configuration is done here. The most common configuration
# options are documented and commented below. For a complete reference,
# please see the online documentation at vagrantup.com.

# A good solution would be http://serverfault.com/questions/418422/public-static-ip-for-vagrant-boxes
FileUtils.makedirs('manifests')
FileUtils.makedirs('modules')

Vagrant.configure("2") do |config|
  config.vm.box_url = boxUrl
  config.vm.network :public_network
end

Vagrant::Config.run do |config|
  puts "Using boxUrl #{boxUrl}"

  config.vm.boot_mode = :gui # :gui or :headless (default)
  config.vm.provision :puppet, :options => "--debug"
  config.vm.share_folder "hieradata", "/etc/puppet/hieradata", File.join(Dir.pwd, 'hieradata')
  config.vm.customize  ["modifyvm", :id, "--memory", 1024, "--cpus", 1,  ]

  config.vm.provision :shell, :path => "shell/main.sh"
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "site.pp"
    puppet.module_path = "modules"
  end

  config.vm.define :srv do |srv|  
    srv.vm.host_name = "srv.#{`hostname -d`.chomp}"
    srv.vm.network :bridged, { :mac => '000000250125', :bridge => bridgedNetworkAdapter, :ip => '172.25.1.25' } # dhcp from fest
    srv.vm.box     = boxId
    srv.vm.box_url = boxUrl
    srv.vm.forward_port   22, firstPort +  22    # ssh
    srv.vm.forward_port   80, firstPort +  80    # Apache
  end if systemsToBoot.index(:srv)
    
end
