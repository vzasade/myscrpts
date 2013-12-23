require 'rubygems'
require 'fileutils'

if ARGV.length != 1
  puts 'Please specify dir!'
  exit -1
end

src_dir = ARGV[0]

class FNameCounter
 def initialize()
   @cntr = 1
   @dest_dir = "d:\\flacs_to_go\\_pics"
end
 
 def nextFname_int()
    name = sprintf("%02d.jpg", @cntr)
    @cntr = @cntr + 1
    return name
 end

 def nextFname()
    while true do
       name = @dest_dir + "\\" + nextFname_int()
       if !File.exist?(name)
          return name
       end
    end
 end
   
end

def getHeight(fname)
   ext = File.extname(fname)
   fname = fname.gsub(/\\/, '/')
   fname = File.basename(fname, ext)
   fname = fname.slice(/xx[0-9]+$/)
   if (fname == nil)
      return 800
   end
   fname = fname.slice(2, fname.length - 2) #skip xx
   i = Integer(fname)
   
   if (i < 100 or i > 20000)
      return 800
   end
   
   return i
end

fcntr = FNameCounter.new
names = Array.new

Dir.foreach(src_dir) do |f|
   fname = src_dir + "\\" + f
   if f == '.' or f == '..' then next
   elsif File.directory?(fname) then next      
   else
     names << f
   end
end

names.sort! { |a, b| a.casecmp b }

names.each do |f|
   fname = src_dir + "\\" + f

   ext = File.extname(fname).downcase
   if ext == '.jpg' or ext == '.png' or ext == '.gif' or ext == '.jpeg' or ext == '.tif' or ext == '.tiff' or ext == '.bmp'
      height = getHeight(fname)
      new_name = fcntr.nextFname()
      cmdline = 'convert "' + fname + '" -quiet -resize "x' + height.to_s + '>" "' + new_name + '"'
      puts 'execute: ' + cmdline
      system cmdline
      puts 'DONE'
   end
end



