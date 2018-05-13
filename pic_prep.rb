require 'rubygems'
require 'fileutils'

if ARGV.length < 1
  puts 'Please specify dir!'
  exit -1
end

$defaultH = 800
if ARGV.length > 1
  h = ARGV[1].to_i
  if h < 200 or h > 10000
    puts 'not allowed default height ' + ARGV[1]
    exit -1
  end
  puts 'changing default height to ' + ARGV[1]
  $defaultH = h
end

$startCnt = 1
if ARGV.length > 2
  h = ARGV[2].to_i
  if h < 1 or h > 99
    puts 'not allowed starting counter ' + ARGV[2]
    exit -1
  end
  puts 'starting files count from ' + ARGV[2]
  $startCnt = h
end

src_dir = ARGV[0]

puts 'process dir ' + ARGV[0]

class FNameCounter
 def initialize()
   @cntr = $startCnt
   @dest_dir = "c:\\music\\_pics"
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
      return $defaultH
   end
   fname = fname.slice(2, fname.length - 2) #skip xx
   i = Integer(fname)

   if (i < 100 or i > 20000)
      return $defaultH
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
      # http://www.imagemagick.org/script/convert.php
      cmdline = '"C:\Program Files\ImageMagick-6.9.3-Q16\convert.exe" "' + fname + '" -quiet -quality 80 -resize "x' + height.to_s + '>" "' + new_name + '"'
      puts 'execute: ' + cmdline
      system cmdline
      puts 'DONE'
   end
end
