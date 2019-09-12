require 'rubygems'
require 'fileutils'
require 'find'
require 'taglib'
require 'pathname'
require 'yaml'
require File.dirname(__FILE__) + '/track_tag_lib.rb'

def dirName2Album(alb_name)
  ind = alb_name.index(' - ')
  ind != nil or raise "Incorrect album dir: " + alb_name
  {"artist" => alb_name[0..ind-1], "name" => alb_name[ind+3..alb_name.length]}
end

def setCommonAlbumVar(album, key, value)
  value != nil or raise key + " is not specified"

  if album[key] == nil then
    album[key] = value
  else
    album[key] == value or raise key + " [" + value.to_s + "] does not match [" + album[key].to_s + "."
  end

  return album
end

def setMinMaxValues(album, min_field, max_field, value)
  if album[min_field] != nil
    if value < album[min_field].to_i
      album[min_field] = value.to_s
    end
  else
    album[min_field] = value.to_s
  end

  if album[max_field] != nil
    if value > album[max_field].to_i
      album[max_field] = value.to_s
    end
  else
    album[max_field] = value.to_s
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
  
  if album['gain'] == nil
    album['gain'] = "0"
  end

  if album['gain'].end_with?(' dB')
    album['gain'] = album['gain'].slice(0, album['gain'].length() - 3)
  end

  album["size"] = '%.2f' % ((album["size"]/1024.0)/1024.0)
  album["length"] = Time.at(album["length"]).gmtime.strftime('%R:%S')

  return album
end

def validateName(path)
  name = File.basename(path, File.extname(path))
  md = /\A\d\d-(\d|\w|[\&\#\!\;\,\. '\(\)\[\]\=\+-])*/.match(name)
  if md[0] != name then
     raise "Unsupported symbol after " + md[0] + " path = " + path
  end
end

def processTrack(track, album)
  album = setCommonAlbumVar(album, "artist", track[:artist])
  album = setCommonAlbumVar(album, "name", track[:album])
  album = setCommonAlbumVar(album, "year", track[:year])
  album = setMinMaxValues(album, "audio_bitrate_min", "audio_bitrate_max", track[:bitrate])
  album = setMinMaxValues(album, "audio_sample_rate_min", "audio_sample_rate_max", track[:sample_rate])
  album = setMinMaxValues(album, "audio_sample_width_min", "audio_sample_width_max", track[:sample_width])
  album["length"] = album["length"] + track[:length]
  album["size"] = album["size"] + track[:size]

  if track[:type] == 'FLAC' then
    album = setBitrate(album, "FLAC")
  else
    album = setBitrate(album, track[:bitrate])
  end

  album = setCommonAlbumVar(album, "gain", track[:album_gain])
  album = setCommonAlbumVar(album, "peak", track[:album_peak])

  return album
end

def processAlbum(path)
  albumDir = Pathname.new(path).basename.to_s
  # puts "Processing Album: " + albumDir

  album = dirName2Album(albumDir)
  album["size"] = 0
  album["length"] = 0

  Find.find(path) do |path|
    if FileTest.directory?(path)
      next
    end

    begin
      track = readTag(path)
      if track == nil
        next
      end

      puts "Processing: " + Pathname.new(path).basename.to_s
      validateName(path)

      album = processTrack(track, album)
    rescue Exception => e
      puts "Error processing file %s" % path
      raise e
    end
  end

  album = postprocess(album)
  # puts album
  return album
end
