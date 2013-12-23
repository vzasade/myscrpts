require 'rubygems'
require 'fileutils'
require 'find'
require 'taglib'

def getLastPathElem(path)
   ind = path.rindex('\\')
   if (ind == nil) or (ind >= path.length-1)
    puts "Incorrect path: " + path
    exit(0)
  end
  return path[ind+1..path.length()-1]
end

def getExt(path)
  ind = path.rindex('.')
  if (ind == nil)
    return null
  end
  if (ind >= path.length-1)
    puts "Incorrect file name: " + path
    exit(0)
  end
  return path[ind+1..path.length()-1]
end

def getFileName(nameWithExt)
  ind = nameWithExt.rindex('.')
  if (ind == nil)
    return nameWithExt
  end
  
  if (ind <= 0)
    puts "Incorrect file name: " + nameWithExt
    exit(0)
  end
  return nameWithExt[0..ind-1]
end

def dirName2Album(alb_name)
   ind = alb_name.index(' - ')
   if (ind == nil)
    puts "Incorrect album dir: " + alb_name
    exit(0)
  end
  
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

