require 'find'

# Simple File.find by c00lryguy
# Thanks to justinwr for adding what I forgot to do
# ------------------------------
# Usage: 
#     * = wildcard in filename
#   File.find("E:\\") => All files in E:\
#   File.find("E:\\Ruby", "*.rb") => All .rb files in E:\Ruby
#   File.find("E:\\", "*.rb", false) => All .rb files in E:\, but not in its subdirs
class File
  def self.find(dir, filename="*.*", subdirs=true)
    Dir[ subdirs ? File.join(dir.split(/\\/), "**", filename) : File.join(dir.split(/\\/), filename) ]
  end
end

def iterateLJFiles(sub_dir, name)
   root_dir = File.join('D:', 'photos', '03_lj', sub_dir)

   if !FileTest.directory?(root_dir)
      puts "DIR NOT FOUND: " + root_dir;
      exit -1
   end

   Dir.chdir(root_dir)

   numes = []

   Dir.glob(name + '*.jpg') do |fileName|
      if FileTest.directory?(File.join(root_dir, fileName)) 
         next
      end
  
      num = fileName.gsub(name, '')
      num = num.gsub('.jpg', '')
  
      numes << num
   end

   numes = numes.sort {|x,y| x.to_i <=> y.to_i}

   numes.each do |num|
      yield root_dir, "/lj/" + sub_dir, name + num + '.jpg'
   end
end
