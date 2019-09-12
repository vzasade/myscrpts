require 'rubygems'
require 'fileutils'
require 'taglib'
require 'pathname'

def readTag(path)
  fileExt = Pathname.new(path).extname

  if (fileExt == '.mp3' || fileExt == '.flac') then
    track = readCommonTag(path)

    if (fileExt == '.mp3')
      track[:type] = 'MP3'
      track = readMp3Tag(path, track)
    end

    if (fileExt == '.flac')
      track[:type] = 'FLAC'
      track = readFlacTag(path, track)
    end

    return track
  end
  return nil
end

def readFlacTag(path, track)
  TagLib::FLAC::File.open(path) do |file|
    track[:sample_width] = file.audio_properties.sample_width

    tag = file.xiph_comment
    raise "Cannot find xiph_comment" if tag == nil
    fields = tag.field_list_map

    track[:gain] = getFlacFieldVal(fields, 'REPLAYGAIN_TRACK_GAIN')
    track[:peak] = getFlacFieldVal(fields, 'REPLAYGAIN_TRACK_PEAK')
    track[:album_gain] = getFlacFieldVal(fields, 'REPLAYGAIN_ALBUM_GAIN')
    track[:album_peak] = getFlacFieldVal(fields, 'REPLAYGAIN_ALBUM_PEAK')
    track[:album_artist] = getFlacFieldVal(fields, 'ALBUMARTIST')
    track[:total] = getFlacFieldVal(fields, 'TOTALTRACKS').to_i
    return track
  end
  raise "Cannot read file."
end

def getFlacFieldVal(fields, name)
  field = fields[name]
  raise "Missing field %s" % name if field == nil
  return field[0]
end

def readMp3Tag(path, track)
  TagLib::MPEG::File.open(path) do |file|
    prop = file.audio_properties
    track[:sample_width] = 16
    # not sure why it is here
    track[:bitrate] = prop.bitrate

    tNums = getID3v2TextFrame(file, 'TRCK').split("/")
    raise "Incorrect TRCK frame" if tNums.size != 2

    track[:total] = tNums[1].to_i
    track[:album_artist]  = getID3v2TextFrame(file, 'TPE2')
    track[:album_gain] = getID3v2Field(file, 'TXXX', 'replaygain_album_gain')
    track[:album_peak] = getID3v2Field(file, 'TXXX', 'replaygain_album_peak')
    track[:gain] = getID3v2Field(file, 'TXXX', 'replaygain_track_gain')
    track[:peak] = getID3v2Field(file, 'TXXX', 'replaygain_track_peak')
    return track
  end
  raise "Cannot read file."
end

def getID3v2TextFrame(file, frame)
  file.id3v2_tag.frame_list(frame)[0].field_list[0]
end

def getID3v2Field(file, frame, field)
  tag = file.id3v2_tag
  frames = tag.frame_list(frame)
  frames.each do |f|
    if f.field_list[0] == field then
      return f.field_list[1]
    end
  end
  raise "Field %s not found in %s frame of id3v2 tag" % [field, frame]
end

def readCommonTag(path)
  TagLib::FileRef.open(path) do |file|
    tag = file.tag;

    if tag == nil then
      raise "There's no tag on file %s" % path
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

    return {:bitrate => bitrate,
            :size => filesize,
            :artist => tag.artist,
            :album => tag.album,
            :title => tag.title,
            :track => tag.track,
            :year => tag.year,
            :genre => tag.genre,
            :sample_rate => file.audio_properties.sample_rate,
            :length => file.audio_properties.length}
  end
  raise "Cannot read file."
end
