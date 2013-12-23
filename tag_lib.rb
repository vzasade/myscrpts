# unused stuff from flac2mp3

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
    TagLib::FileRef.open(filePath) do |fileref|
      tag = fileref.tag
    end     
    
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
  
  def setToMp3(filePath)
    # Load a tag from a file
    tag = ID3Lib::Tag.new(filePath)
    
    tag.album = @album
    tag.track = @tracknumber
    tag.title = @title
    tag.artist = @artist
    tag.year = @year
    tag.genre = @genre
    tag.update!
  end  
end
