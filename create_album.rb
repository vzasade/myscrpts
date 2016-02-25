require 'rubygems'
require 'net/http'
require 'fileutils'
require 'find'
require 'pathname'
require File.dirname(__FILE__) + '/mdb_common.rb'

def setAlbumVar(album, key, value)
  value != nil or raise key + " is not specified"

  if album[key] == nil then
    album[key] = value
  else
    album[key] == value or raise key + " [" + value + "] does not match [" + album[key] + "."
  end

  return album
end

def setBitrate(album, value)
  if album[:bitrate] == nil
    album[:bitrate] = {}
  end
  if value == 'FLAC'
    album[:bitrate][value] = 'X'
  else
    max = 0
    min = 100000
    if album[:bitrate]["MAX"] != nil
      max = album[:bitrate]["MAX"].to_i
    end

    if album[:bitrate]["MIN"] != nil
      min = album[:bitrate]["MIN"].to_i
    end

    if max < value.to_i
      max = value.to_i
    end

    if min > value.to_i
      min = value.to_i
    end

    album[:bitrate]["MAX"] = max.to_s
    album[:bitrate]["MIN"] = min.to_s
  end

  return album
end

def postprocess(album)
  bitrate = ""
  if album[:bitrate]['FLAC'] == 'X'
    bitrate += 'FLAC'
  end

  if album[:bitrate]["MAX"] != nil && album[:bitrate]["MIN"] != nil
    if bitrate != ""
      bitrate += ","
    end

    if album[:bitrate]["MAX"] == album[:bitrate]["MIN"]
      bitrate += album[:bitrate]["MAX"]
    else
      bitrate += album[:bitrate]["MIN"] + "-" + album[:bitrate]["MAX"]
    end
  end

  album.delete(:bitrate)
  album['bitrate'] = bitrate;

  if album['gain'].end_with?(' dB')
    album['gain'] = album['gain'].slice(0, album['gain'].length() - 3)
  end

  album["size"] = '%.2f' % ((album["size"]/1024.0)/1024.0)
  album["length"] = Time.at(album["length"]).gmtime.strftime('%R:%S')

  return album
end

def processFile(path, album)
  puts "Processing: " + Pathname.new(path).basename.to_s

  TagLib::FileRef.open(path) do |file|
    tag = file.tag;

    if tag == nil then
      puts "There's no tag on file."
      exit(0)
    end

    album = setAlbumVar(album, "artist", tag.artist)
    album = setAlbumVar(album, "name", tag.album)
    album = setAlbumVar(album, "year", tag.year)

    properties = file.audio_properties
    album["length"] = album["length"] + properties.length

    album["size"] = album["size"] + File.size(path)

    return album
  end

  raise "Cannot read file."
end

def processMp3(path, album)
  gain = getMp3RG(path)
  album = setAlbumVar(album, "gain", gain)

  TagLib::FileRef.open(path) do |file|
    prop = file.audio_properties
    album = setBitrate(album, prop.bitrate)
    puts prop.bitrate
    puts prop.length
  end
  return album
end

def processFlac(path, album)
  gain = getFlacRG(path)
  album = setAlbumVar(album, "gain", gain)
  album = setBitrate(album, "FLAC")
  return album
end

def processDir(path)
  albumDir = Pathname.new(path).basename.to_s
  puts "Processing Album: " + albumDir

  album = dirName2Album(albumDir)
  album["size"] = 0
  album["length"] = 0

  Find.find(path) do |subdirPath|
    if FileTest.directory?(subdirPath)
      next
    end

    filePath = subdirPath
    fileExt = Pathname.new(filePath).extname

    if (fileExt == '.mp3' || fileExt == '.flac')
      album = processFile(filePath, album)

      if (fileExt == '.mp3')
        album = processMp3(filePath, album)
      end

      if (fileExt == '.flac')
        album = processFlac(filePath, album)
      end
    end
  end

  album = postprocess(album)
  puts album

  x = Net::HTTP.post_form(URI.parse('http://www.vzasade.com/mdb/pages/api_create_album.php'), album)

  body = x.body
  update = false;

  if body.start_with?('U.')
    update = true
    body = body.slice('U.'.length, body.length - 'U.'.length)
  end

  if body.start_with?('row_id:')
    body = body.slice('row_id:'.length, body.length - 'row_id:'.length)
    puts "Album ID: " + body
    if update
      puts "Album updated. ID=" + body
    else
      puts "Album created. ID=" + body
      uploadPictures(body)
    end

    if ENV['BROWSER'] != nil
      exec("\"" + ENV['BROWSER'] + "\" \"http://vzasade.com/mdb/pages/main.php?row_id=" + body + "\"");
    end
  else
    puts "ERROR: " + body
  end

  exit(0)

end

######################################################
# Body
######################################################

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  puts 'USAGE: create_album.rb <path to album dir>'
  exit -1
end

processDir(ARGV[0])
