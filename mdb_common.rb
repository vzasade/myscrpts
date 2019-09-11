require 'rubygems'
require 'fileutils'
require 'find'
require 'taglib'
require 'pathname'
require 'yaml'

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

def processMp3ReplyGain(album, file)
  tag = file.id3v2_tag
  frames = tag.frame_list('TXXX')

  frames.each do |frame|
    next if frame.field_list.size != 2
    if frame.field_list[0] == 'replaygain_album_gain'
      album = setCommonAlbumVar(album, "gain", frame.field_list[1])
    elsif frame.field_list[0] == 'replaygain_album_peak'
      album = setCommonAlbumVar(album, "peak", frame.field_list[1])
    end
  end
  return album
end

def getFlacFieldVal(fields, name)
  field = fields[name]
  return nil if field == nil
  return field[0]
end

def processFlacReplyGain(album, file)
  tag = file.xiph_comment
  return nil if tag == nil
  fields = tag.field_list_map

  album = setCommonAlbumVar(album, "gain", getFlacFieldVal(fields, 'REPLAYGAIN_ALBUM_GAIN'))
  return setCommonAlbumVar(album, "peak", getFlacFieldVal(fields, 'REPLAYGAIN_ALBUM_PEAK'))
end

def validateName(path)
  name = File.basename(path, File.extname(path))
  md = /\A\d\d-(\d|\w|[\&\#\!\;\,\. '\(\)\[\]\=\+-])*/.match(name)
  if md[0] != name then
     raise "Unsupported symbol after " + md[0] + " path = " + path
  end
end

def processFile(path, album)
  puts "Processing: " + Pathname.new(path).basename.to_s
  validateName(path)

  TagLib::FileRef.open(path) do |file|
    tag = file.tag;

    if tag == nil then
      puts "There's no tag on file."
      exit(0)
    end
	
	bitrate = file.audio_properties.bitrate
	filesize = File.size(path)
	calc_bitrate = filesize / (128 * file.audio_properties.length)
	
	# sometimes bitrate is just incorrect
	#   in some cases it is because the big pic is attached to a small file
	#   in some cases it is just wrong, though winamp shows it correctly
	#      example: Miles Davis - Big Fun (LP)
	if bitrate < calc_bitrate * 0.8 then
		puts "Detected incorrect bitrate : %d vs %d = %d / (128 * %d), file = %s" % [bitrate, calc_bitrate, filesize, file.audio_properties.length, path]
		bitrate = calc_bitrate
	end

    album = setCommonAlbumVar(album, "artist", tag.artist)
    album = setCommonAlbumVar(album, "name", tag.album)
    album = setCommonAlbumVar(album, "year", tag.year)
    album = setMinMaxValues(album, "audio_bitrate_min", "audio_bitrate_max", bitrate)
    album = setMinMaxValues(album, "audio_sample_rate_min", "audio_sample_rate_max", file.audio_properties.sample_rate)
    # puts "bitrate: " + bitrate.to_s
    # puts "length: " + file.audio_properties.length.to_s

    properties = file.audio_properties
    album["length"] = album["length"] + properties.length

    album["size"] = album["size"] + File.size(path)

    return album
  end

  raise "Cannot read file."
end

def processMp3(path, album)
  TagLib::MPEG::File.open(path) do |file|
    prop = file.audio_properties
    album = setMinMaxValues(album, "audio_sample_width_min", "audio_sample_width_max", 16)
    album = processMp3ReplyGain(album, file)
    album = setBitrate(album, prop.bitrate)
  end
  return album
end

def processFlac(path, album)
  TagLib::FLAC::File.open(path) do |file|
    album = setMinMaxValues(album, "audio_sample_width_min", "audio_sample_width_max", file.audio_properties.sample_width)
    album = processFlacReplyGain(album, file)
    album = setBitrate(album, "FLAC")
  end
  return album
end

def processAlbum(path)
  albumDir = Pathname.new(path).basename.to_s
  # puts "Processing Album: " + albumDir

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
  # puts album
  return album
end
