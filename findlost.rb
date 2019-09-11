require 'net/http'
require 'uri'
require 'json'

require File.dirname(__FILE__) + '/mdb_common.rb'

def getDiskPath(disk)
  return 'E:\\jukebox\\VOL_1\\' + disk
end

def processDisk(disk)
  disk = disk.to_s.rjust(3, '0')

  path = getDiskPath(disk)

  if path == ''
    puts "Disk not found: " + disk
    return
  end

  albums_text = Net::HTTP.get URI.parse('http://www.vzasade.com/mdb/rest/query/goodAlbums/'+disk)
  
  albums = JSON.parse(albums_text)
  albums.each do |album|
    pathToAlbum = path + "\\" + album["artist"] + ' - ' + album["name"]
	begin
      onDisk = processAlbum(pathToAlbum)
	
	  if (onDisk["gain"].to_f * 100).to_i != (album["gain"] * 100).to_i
	    puts "Mismatch gain " + onDisk["gain"] + " vs. " + album["gain"].to_s + "!!! " + pathToAlbum
	  end

	  if onDisk["size"].to_i != album["size"].to_i
	    puts "Mismatch size " + onDisk["size"] + " vs. " + album["size"].to_s + "!!! " + pathToAlbum
	  end
	rescue Exception => e
	  puts pathToAlbum
	  puts e
	  puts e.backtrace
	end
	
  end
end

(244..244).each do |i|
  puts "Processing " + i.to_s
  processDisk(i)
end
