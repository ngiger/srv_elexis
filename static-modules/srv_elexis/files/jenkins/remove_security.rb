#!/usr/bin/env ruby

require "rexml/document"
include REXML  # so that we don't have to prefix everything with REXML::...
doc = Document.new IO.read('config.xml')
doc.elements.each('hudson/useSecurity'){ |element| element.text='false'}
doc.elements.delete('hudson/authorizationStrategy') # { |element| element.delete }
doc.elements.delete('hudson/securityRealm')
File.open('config.no_security', 'w+') { |f| f.puts doc  }