require File.dirname(__FILE__) + '/lj_utl.rb'
require File.dirname(__FILE__) + '/../deployment/deploy_lib.rb'
require File.dirname(__FILE__) + '/../deployment/http_proxy.rb'

if ARGV.length != 2
  puts 'Incorrect number of arguments!'
  exit -1
end

sub_dir = ARGV[0]
name = ARGV[1]

Net::HTTP.version_1_2

httpStartWithProxy ("www.vzasade.com") do |http|
   login(http) do |sid|
      makeDir(http, sid, "/lj/" + sub_dir)
      iterateLJFiles(sub_dir, name) do |src, dest, f_name|
         deployFile(http, sid, f_name, src, dest)
      end
   end
end
