# -*- mode: ruby -*-
# vi: set ft=ruby :

#------------------------------------------------------------------------------------------------------------
# Some simple customization below
#------------------------------------------------------------------------------------------------------------
# boxUrl = "https://atlas.hashicorp.com/ARTACK/boxes/debian-jessie"
#boxUrl = "https://vagrantcloud.com/lazyfrosch/boxes/debian-8-jessie-amd64-puppet"
# boxUrl = 'hoppe/debian-8.2.0-amd64'
#boxUrl = 'https://atlas.hashicorp.com/markusperl/boxes/debian-8.0-jessie-64-shrinked-puppet'
#puts "Using boxUrl #{boxUrl}"

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
  config.vm.box   =  'deb/jessie-amd64'
  config.vm.provider "virtualbox" do |v|
    v.gui = true
    v.memory = 2048
    v.cpus = 2
  end

  #  config.vm.box     = 'lazyfrosch/debian-8-jessie-amd64-puppet'
  # config.vm.box     =  'puppetlabs/debian-8.2-64-puppet'
  # config.vm.box_version = "1.0.1

  # config.vm.provision :puppet, :options => "--debug"
  # config.vm.provision "shell", inline: "apt-get update && apt-get upgrade --yes"
  # config.vm.provision "shell", inline: "apt-get install --yes puppet"
  config.vm.provision :shell, :path => "shell/main.sh"
  # apply on the server using vagrant@srv /vagrant> sudo -iHu root puppet apply --confdir /vagrant --noop --debug --modulepath=/vagrant/modules/ /vagrant/modules/srv_elexis/tests/init.pp
  if true # puppet > 4.0
    config.vm.provision "shell", inline: "/opt/puppetlabs/bin/puppet apply --modulepath=/vagrant/modules /vagrant/manifests/site.pp"
  else
    config.vm.provision :puppet do |puppet|
      # puppet.manifests_path = "manifests"
      puppet.manifest_file = "site.pp"
      puppet.module_path = "modules"
    end
  end

  config.vm.host_name = "srv.#{`hostname -d`.chomp}"
  config.vm.network "public_network", bridge: 'br0', :mac => '000000250125'
  config.vm.network "forwarded_port", guest: 80, host: firstPort + 80
  config.vm.network "forwarded_port", guest: 22, host: firstPort + 22
end
