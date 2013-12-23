require File.dirname(__FILE__) + '/../deployment/deploy_lib.rb'
require File.dirname(__FILE__) + '/../deployment/http_proxy.rb'

$work_dir = ENV['MY_WORK_DIR']
puts File.join($work_dir, "mdb")

def deployWorkDir(http, sid, pattern, dir)
  deployDir(http, sid, pattern, $work_dir + dir, dir)
end

if $work_dir == nil
   puts "MY_WORK_DIR is not set"
   exit -1
else
	puts "Work Dir: " + $work_dir 
end

if ARGV.length != 1
  puts 'Please specify target!'
  exit -1
end

target = ARGV[0]

if __FILE__ == $0
   Net::HTTP.version_1_2

   if target == 'mdb'
      httpStartWithProxy ("www.vzasade.com") do |http|
         login(http) do |sid|
            deployWorkDir(http, sid, "*.*", '/mdb')
            deployWorkDir(http, sid, "*.*", '/mdb/db_objects')
            deployWorkDir(http, sid, "*.*", '/mdb/admin')
            deployWorkDir(http, sid, "*.*", '/mdb/pages')
            deployWorkDir(http, sid, "*.*", '/mdb/pics')
            deployWorkDir(http, sid, "*.*", '/mdb/style')
         end
      end
   elsif target == 'deployment'
      httpStartWithProxy ("www.vzasade.com") do |http|
         login(http) do |sid|
            deployWorkDir(http, sid, "*.php", '/deployment')
         end
      end
   else
      puts 'Unknown target: ' + target           
   end
end