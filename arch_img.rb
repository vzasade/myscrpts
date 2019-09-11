require 'json'
require 'fileutils'

base = 'G:\\img_backup'
opath = 'G:\\test'

def processDisk(num, opath, base)
  diskStr = num.to_s.rjust(5, "0")
  diskOPath = File.join(opath, diskStr)
  diskIPath = File.join(base, diskStr)
  puts "DISK: " + diskStr
  FileUtils::mkdir_p diskOPath
  Dir.foreach(diskIPath) do |subdir|
    fullDir = File.join(diskIPath, subdir)
    if subdir == '.' or subdir == '..' then next
    elsif !File.directory?(fullDir) then next
    else
      puts "   " + subdir
      oFile = File.join(diskOPath, subdir + ".ar")
      processDir(fullDir, oFile)
    end
  end
end

def processDir(ipath, opath)
  jArr = Array.new
  Dir.foreach(ipath) do |f|
    fname = File.join(ipath, f)
    if f == '.' or f == '..' then next
    elsif File.directory?(fname) then next
    else
      jArr.push({"name" => f, "size" => File.size?(fname)})
    end
  end

  jStr = JSON.generate(jArr)
  jStrLength = jStr.length

  File.open(opath, 'wb') do |ofile|
    ofile.write([jStrLength].pack("i"))
    ofile.write(jStr)

    jArr.each do |item|
      copyFile(File.join(ipath, item["name"]), ofile)
    end
  end
end

def copyFile(path, ofile)
  File.open(path,'rb') do |f|
    while true do
      buffer = f.read(1024)
      break if buffer == nil
      ofile.write(buffer)
    end
  end
end

(33..34).each do |i|
  processDisk(i, opath, base)
end
