require 'fileutils'
require File.dirname(__FILE__) + '/../deployment/deploy_lib.rb'
require File.dirname(__FILE__) + '/../deployment/http_proxy.rb'

if ARGV.length != 1
  puts 'Please specify target!'
  exit -1
end

target = ARGV[0]

if target == 'start'
  cleanPictures()
else
  uploadPictures(target)
end
