require 'net/http'
require 'uri'
require File.dirname(__FILE__) + '/mdb_common.rb'

def getDiskPath(disk)
  locations = ['E:\\jukebox\\VOL_1\\','E:\\jukebox\\VOL_2\\','E:\\jukebox\\VOL_3\\']

  for prefix in locations
    path = prefix + disk

    if (FileTest.directory?(path))
      return path
    end
  end
  return ''
end

def processDisk(disk)
  disk = disk.to_s.rjust(3, '0')

  path = getDiskPath(disk)

  if path == ''
    puts "Disk not found: " + disk
    return
  end

  albums_text = Net::HTTP.get URI.parse('http://www.vzasade.com/mdb/pages/unchecked.php?disk='+disk)
  albums = albums_text.split('||')

  albums.each do |album_str|
    album = album_str.split('|')

    albumDir = album[1]+' - '+album[2]
    pathToAlbum = path + "\\" + albumDir

    if (FileTest.directory?(pathToAlbum))
      puts pathToAlbum
      begin
        alb = processAlbum(pathToAlbum)
        alb["row_id"] = album[0]
        x = Net::HTTP.post_form(URI.parse('http://www.vzasade.com/mdb/pages/api_act.php'), alb)
        puts x.body
      rescue RuntimeError => oops
        puts oops
      rescue NoMethodError => oops
        puts oops
      end
    else
      puts "Album not found: " + pathToAlbum
    end
  end
end

(1..179).each do |i|
  processDisk(i)
end
