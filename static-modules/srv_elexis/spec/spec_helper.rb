require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.default_facts = {
    :operatingsystem        => 'Debian',
    :osfamily               => 'Debian',
    :operatingsystemrelease => 'wheezy',
    :lsbdistcodename        => 'wheezy',
    :lsbdistid              => 'debian',
      # for concat/manifests/init.pp:193
    :id                     => 'id',
    :concat_basedir         => '/opt/concat',
    :path                   => '/path',
  }
end
# at_exit { RSpec::Puppet::Coverage.report! }
