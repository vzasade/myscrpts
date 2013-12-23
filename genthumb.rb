require 'rubygems'
require 'RMagick'

if __FILE__ == $0
  # TODO Generated stub
end

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  exit -1
end

sub_dir = ARGV[0]

$root_dir = 'D:\work'
$blog_root = 'http://blogs.oracle.com/ensemble/resource/'

def iterateBlogFiles(sub_dir)
  root_dir = File.join($root_dir, sub_dir)
  
   if !FileTest.directory?(root_dir)
      puts "DIR NOT FOUND: " + root_dir;
      exit -1
   end

   Dir.chdir(root_dir)

   names = []

   Dir.glob('*.jpg') do |fileName|
      if FileTest.directory?(File.join(root_dir, fileName)) 
         next
      end
  
      names << fileName
   end

   names.each do |name|
      img = Magick::Image::read(File.join(root_dir, name)).first
      yield name, img.rows, img.columns
   end
end

def getFileEntry(sub_dir, name, rows, cols)
  if rows > cols
    t_rows = 250
    t_cols = (cols * 250) / rows
  else
    t_cols = 250
    t_rows = (rows * 250) / cols
  end
  
  rows = rows + 20
  cols = cols + 20
  
  url = $blog_root + sub_dir + "/" + name
  entry = "<p>\n"
  entry += "<a href=\"" + url + "\" target=\"" + name + "\" onclick=\"window.open(&quot;" + url + "&quot;, &quot;" + name + "&quot;, "
  entry += "&quot;height=" + rows.to_s() + ",width=" + cols.to_s() + ",menubar=no,status=no,toolbar=no&quot;); return false;\">\n"
  entry += "<img border=\"0\" align=\"absmiddle\" style=\"height: " + t_rows.to_s() + "px; width: " + t_cols.to_s() + "\" "
  entry += "src=\"" + url +"\" /></a>\n</p>\n"
end

iterateBlogFiles(sub_dir) do |f_name, rows, cols|
  puts getFileEntry(sub_dir, f_name, rows, cols)
end

