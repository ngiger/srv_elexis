# -*- mode: ruby -*-
# vi: set ft=ruby :

#------------------------------------------------------------------------------------------------------------
# Some simple customization below
#------------------------------------------------------------------------------------------------------------
# boxUrl = "https://atlas.hashicorp.com/ARTACK/boxes/debian-jessie"
boxUrl = "https://vagrantcloud.com/lazyfrosch/boxes/debian-8-jessie-amd64-puppet"
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
  config.vm.box     = 'lazyfrosch/debian-8-jessie-amd64-puppet'
  # config.vm.box_url = boxUrl
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
  config.vm.network "public_network", bridge: 'br0', :mac => '000000250125'
  config.vm.network "forwarded_port", guest: 80, host: firstPort + 80
  config.vm.network "forwarded_port", guest: 22, host: firstPort + 22
end
