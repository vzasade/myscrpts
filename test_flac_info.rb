require 'rubygems'
require 'flacinfo'

@flac_path = 'C:\flacs_to_go\Ornette Coleman - Change of the Century\07-Change of the Century.flac'

class Tag
  
  def readTag(tagName)
    tag = @flac.tags[tagName]
    if tag == nil
      tag = @flac.tags[tagName.downcase]
    end
    if tag == nil
      tag = "<notag>"
    end
    return tag
  end
  
  def readFromFlac(filePath)
    @flac = FlacInfo.new(filePath)

    @tracknumber = readTag('TRACKNUMBER')
    @artist = readTag('ARTIST')
    @album = readTag('ALBUM')
    @title = readTag('TITLE')
    @year = readTag('DATE')
    @genre = readTag('GENRE')
    print
  end
  
  def print
    puts "Writing tag:"
    puts "ARTIST: [" + @artist + "]"
    puts "ALBUM: [" + @album + "]"
    puts "TITLE: [" + @title + "]"
    puts "YEAR: [" + @year + "]"
    puts "GENRE: [" + @genre + "]"
    puts "TRACK: [" + @tracknumber + "]"
  end
end

#if __FILE__ == $0
  
     tag = Tag.new
     tag.readFromFlac(@flac_path)
  
#end