require 'fileutils'
require File.dirname(__FILE__) + '/upload.rb'

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
