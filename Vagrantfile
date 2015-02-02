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
  config.vm.provider "virtualbox" do |v|
    v.gui = true
    v.memory = 2048
    v.cpus = 2
  end
  config.vm.provision :puppet, :options => "--debug"
  # config.vm.share_folder "hieradata", "/etc/puppet/hieradata", File.join(Dir.pwd, 'hieradata')
  # config.vm.synced_folder File.join(Dir.pwd, 'hieradata'), "/etc/puppet/hieradata", type: "nfs"
  # config.vm.synced_folder ".", "/vagrant", type: "rsync",   rsync__exclude: ".git/"
  # config.vm.synced_folder "./hieradata", "/etc/puppet/hiearadata", type: "rsync",   rsync__exclude: ".git/"
  config.vm.provision :shell, :path => "shell/main.sh"
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "site.pp"
    puppet.module_path = "modules"
  end

  config.vm.host_name = "srv.#{`hostname -d`.chomp}"
  # config.vm.network :bridged, { :mac => '000000250125', :bridge => bridgedNetworkAdapter, :ip => '172.25.1.25' } # dhcp from fest
  # config.vm.network :bridged, { :mac => '000000250125', :bridge => bridgedNetworkAdapter, :ip => '172.25.1.25' } # dhcp from fest
  config.vm.network "public_network", bridge: 'br0'
  # config.vm.network "public_network", bridge: = 'br0'
  config.vm.box     = boxId
  config.vm.box_url = boxUrl
  config.vm.network "forwarded_port", guest: 80, host: firstPort + 80
  config.vm.network "forwarded_port", guest: 22, host: firstPort + 22
end
