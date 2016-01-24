#!/bin/bash -v

export DEBIAN_FRONTEND=noninteractive
export APT_OPTIONS="--quiet --assume-yes "
# https://docs.puppetlabs.com/puppet/4.3/reference/dirs_codedir.html
apt-get update && apt-get upgrade $APT_OPTIONS --force-yes

# Directory in which librarian-puppet should manage its modules directory
if [ -d /vagrant ] ; then
  PUPPET_DIR=/vagrant ;
else PUPPET_DIR=/etc/puppet ; fi
if [ ! -d /vagrant ] ; then cp /vagrant/Puppetfile $PUPPET_DIR ; fi

export release_name=`lsb_release --codename --short`
echo release_name is $release_name
export rvm_trust_rvmrcs_flag=1
cd $PUPPET_DIR

# we want to use rvm and puppet installed via gem as the
# puppet installed via apt has hiera 1.1 and therefore chokes
# when seening %{::environment} in its configuration
grep puppet /etc/.gitignore | grep puppet
if [ $? -ne 0  ] ; then
  echo puppet/ >> /etc/.gitignore
fi

# Initialize /etc/puppet/hiera.yaml
df -h | grep hieradata
if [ $? -eq 0  ] ; then
  export HIERA_DATA=/`df -h | grep hieradata | cut -d / -f 2-`
  if [ ! -L /etc/puppet/hiera.yaml ] ; then ln -s $HIERA_DATA/hiera.yaml /etc/puppet/hiera.yaml; fi
  if [ ! -L /etc/hiera.yaml ]        ; then ln -s $HIERA_DATA/hiera.yaml /etc/hiera.yaml; fi
fi

dpkg -l etckeeper | grep ii
if [ $? -ne 0  ] ; then
  apt-get install $APT_OPTIONS git etckeeper &> /var/log/etckeeper.log
fi

# Ensure that Puppet >= 4.3 is installed and path correctly perpended
#   export PATH=/opt/puppetlabs/bin:$PATH.
dpkg -l puppet-agent | grep ii
if [ $? -ne 0  ] ; then
  rm -f puppetlabs-release-pc1-${release_name}.deb
  wget https://apt.puppetlabs.com/puppetlabs-release-pc1-${release_name}.deb
  dpkg -i puppetlabs-release-pc1-${release_name}.deb
  apt-get update
  apt-get install $APT_OPTIONS puppet-agent | tee /var/log/puppet-agent.log
fi
/opt/puppetlabs/bin/puppet --version | grep 4.3

