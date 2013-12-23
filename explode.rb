if __FILE__ == $0
  # TODO Generated stub
end

def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
end


require 'rubygems'
require 'zip/zip'
suppress_warnings{require 'FileUtils'}
require 'find'

def unzip_file (file, destination)
  puts "Unzip " + file + " to " + destination
  Zip::ZipFile.open(file) { |zip_file|
   zip_file.each { |f|
     f_path=File.join(destination, f.name)
     FileUtils.mkdir_p(File.dirname(f_path))
     #puts "Extract " + f.to_s + " to " + f_path
     zip_file.extract(f, f_path) unless File.exist?(f_path)
   }
  }
end

def iterateThroughFiles( dirname )
  Find.find( dirname ) do | thisfile |
    thisfile.gsub!( /\// , '\\' )
    yield(thisfile)
  end
end

def isAllowedJar(fname)
   if fname == 'schemas.jar' or fname == 'adf-loc.jar'
      return true
   else
      puts "Skipping " + fname
   end
end

def isArchive(fname)
  ext = File.extname(fname).downcase
  if (ext == '.ear') or (ext == '.war') or (ext == '.mar')
     return true
  end
  if ext == '.jar'
     return isAllowedJar(File.basename(fname.downcase))
  end
  return false
end

def getDestDir(file)
   return File.join(File.dirname(file), "_" + File.basename(file))
end

def explodeArchive(file, dest_dir)
   unzip_file(file, dest_dir)
   
   file_list = Array.new
   iterateThroughFiles(dest_dir) do |path|
      if !FileTest.directory?(path)
         if isArchive(path)
            file_list.push(path)
         end
      end
   end
   
   file_list.each do |file|
      explodeArchive(file, getDestDir(file))
   end
end

######################################################
# Body
######################################################

if ARGV.length != 2
  puts 'Incorrect number of arguments!'
  puts 'USAGE: explode.rb <archive> <dest_dir>'
  exit -1
end

archive = ARGV[0]
dest_dir = ARGV[1]

if !isArchive(archive)
   raise "This is not an archive"
end

puts "Removing " + dest_dir
FileUtils.rm_rf(dest_dir)
explodeArchive(archive, dest_dir)
