require 'rubygems'
require 'fileutils'
require 'find'
require 'taglib'
require 'pathname'

def dirName2Album(alb_name)
  ind = alb_name.index(' - ')
  ind != nil or raise "Incorrect album dir: " + alb_name
  {"artist" => alb_name[0..ind-1], "name" => alb_name[ind+3..alb_name.length]}
end

def getMp3RG(path)
  TagLib::MPEG::File.open(path) do |file|
    tag = file.id3v2_tag

    frames = tag.frame_list('TXXX')

    frames.each do |frame|
      if frame.field_list.size != 2 then next
      elsif frame.field_list[0] != 'replaygain_album_gain' then next
      else
        return frame.field_list[1]
      end
    end
  end
  return nil
end

def getFlacRG(path)
  TagLib::FLAC::File.open(path) do |file|
    tag = file.xiph_comment
    return nil if tag == nil
    fields = tag.field_list_map

    field = fields['REPLAYGAIN_ALBUM_GAIN']
    if field == nil then
      return nil
    end
    return field[0]
  end
  return nil
end

def setAlbumVar(album, key, value)
  value != nil or raise key + " is not specified"

  if album[key] == nil then
    album[key] = value
  else
    album[key] == value or raise key + " [" + value.to_s + "] does not match [" + album[key].to_s + "."
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

def processAlbum(path)
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
  return album
end
