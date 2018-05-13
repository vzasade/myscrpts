require 'rubygems'
require 'fileutils'
require 'net/ftp'

def maybe_create_dir(ftp, dir)
  puts "AAA " + dir
  begin
    ftp.mkdir dir
  rescue Net::FTPPermError
  end
  ftp.chdir(dir)
end

def file_changed(ftp, name)
  begin
    local = File.stat(name).mtime
    remote = Time.at(ftp.mtime(name, true)) - 8*60*60
    if local > remote then
      return true
    end
    return ftp.size(name) != File.size(name)
  rescue
    return true
  end
end

class String
  def is_integer?
    self.to_i.to_s == self
  end
end

$pics_dir = "c:\\music\\_pics"

def cleanPictures()
  Dir.chdir($pics_dir)
  Dir.glob('*.jpg').each do |name|
    puts "delete: " + name
    File.unlink(name)
  end
end

def uploadPictures(num)
  num.is_integer? or raise "Album ID " + num + " is not numeric"
  num.size <= 6 or raise "Album ID " + num + " is too long"

  Dir.chdir($pics_dir)
  entries = Dir.glob('*.jpg').sort.reverse

  if entries.size == 0 then
    puts "No pictures to upload"
    return
  end

  doUploadPictures(entries, num, 1)
end

def doUploadPictures(entries, num, tries)
  if tries == 10 then
     panic "No more retries!"
  end
  
  if tries > 1 then
     puts "Try one more time"
  end

  num = num.rjust(6, '0')
  dir1 = num.slice(0, 3).rjust(5, '0')
  dir2 = num.slice(3, 3)
  
  Net::FTP.open('www.vzasade.com', 'vzasade', 'bowie1984') do |ftp|
    ftp.chdir('public_html')
    ftp.chdir('mdb_data')
    ftp.chdir('images')

    maybe_create_dir(ftp, dir1)
    maybe_create_dir(ftp, dir2)

	while entries.size > 0
	  name = entries.pop
	  if !uploadFile(ftp, name) then
	    entries.push(name)
		break
	  end
	end
  end
  
  if entries.size > 0 then
    doUploadPictures(entries, num, tries + 1)
  end
end

def uploadFile(ftp, name)
  begin
    if file_changed(ftp, name) then
      puts 'writing: ' + name
      File.open(name) { |file| ftp.putbinaryfile(file, name) }
    end
  rescue StandardError => e
    puts "caught exception #{e}!"
	return false
  end
  return true
end
