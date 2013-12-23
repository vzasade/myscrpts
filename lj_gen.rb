require File.dirname(__FILE__) + '/lj_utl.rb'

if ARGV.length != 2
  puts 'Incorrect number of arguments!'
  exit -1
end

sub_dir = ARGV[0]
name = ARGV[1]

cut_printed = false
iterateLJFiles(sub_dir, name) do |src, dest, f_name|
  puts "<img src=http://www.vzasade.com" + dest + '/' + f_name + ' border=1>'
  if !cut_printed
    cut_printed = true
    puts "<i></i>"
    puts "<lj-cut text=\"\">"
  else
    puts  
  end
end
