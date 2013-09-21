#!/usr/bin/env ruby
require 'fileutils'
# /var/lib/jenkins/jobs/Elexis-3-derivate/config.xml

Dir.chdir File.join(File.dirname(File.dirname(__FILE__)))
dest = File.expand_path(File.join(Dir.pwd, 'static-modules/srv_elexis/files'))

root = '/var/lib/jenkins'
configs = Dir.glob("#{root}/*.xml") + Dir.glob("#{root}/jobs/*/*.xml")
nrBackups = 0
configs.each{
  |cfg| 
    copyTo = File.join(dest, cfg.sub(root, ''))
    unless FileUtils.uptodate?(copyTo,[cfg])
      FileUtils.cp(cfg, copyTo, :verbose => true)
      system("git add #{copyTo}")
      nrBackups += 1
    end
}
puts "Had to backup #{nrBackups} of #{configs.size} configs"