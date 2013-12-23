require 'taglib'
require File.dirname(__FILE__) + '/mdb_common.rb'

if ARGV.length != 1
  puts 'Please specify disk!'
  exit -1
end

disk = ARGV[0]

def getOneDiskPath(drive,disk)
  return drive+':\\jukebox\\'+disk;
end

def getDiskPath(disk)
  drives = ['D','J','Z']

  for drive in drives
    path = getOneDiskPath(drive,disk)
    
    if (FileTest.directory?(path))
      return path
    end
  end
  return ''
end

def processDir(path)
  rg = nil
  new_rg = nil
  Dir.foreach(path) do |f|
    fname = path + "\\" + f
    if f == '.' or f == '..' then next
    elsif File.directory?(fname) then next
    else
      ext = File.extname(fname).downcase
      if ext == '.flac' then
        new_rg = getFlacRG(fname)
      elsif ext == '.mp3' then
        new_rg = getMp3RG(fname)
      else
        if f != 'Thumbs.db' then
          puts "EXTRAFILE: " + path
          puts "FILE: " + fname
          return
        end
      end
      if new_rg == nil then
        puts "NO RG: " + path
        return
      end
      if rg != nil && rg != new_rg then
        puts "VAR RG: " + path
        puts rg
        puts new_rg
        return
      end
      rg = new_rg
    end
  end
  if rg == nil
     puts "NO RG: " + path
     return
  end
end

path = getDiskPath(disk)
if path == '' then
  puts 'Path for disk ' + disk + ' is not found!'
  exit -1
end

Dir.foreach(path) do |f|
  dirname = path + "\\" + f

  if f == '.' or f == '..' then next
  elsif !File.directory?(dirname) then next
  else
    processDir(path + "\\" + f)
  end
end





