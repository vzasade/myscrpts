require 'rubygems'
require 'fileutils'
require 'find'
require 'taglib'

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
