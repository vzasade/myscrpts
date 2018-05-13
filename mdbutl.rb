require 'net/http'
require 'uri'
require 'find'
require 'pathname'

def getDiskPath(disk)
  locations = ['E:\\jukebox\\VOL_1\\','E:\\jukebox\\VOL_2\\','E:\\jukebox\\VOL_3\\']

  for prefix in locations
    path = prefix + disk

    if (FileTest.directory?(path))
      return path
    end
  end
  return ''
end

def getPrefix(path)
  if path.include? "VOL_1"
    return '\\VOL_1\\'
  elseif path.include? "VOL_2"
    return '\\VOL_2\\'
  else
    return '\\VOL_3\\'
  end
end

albums_text = Net::HTTP.get URI.parse('http://www.vzasade.com/mdb/pages/no_playlist_int.php')

albums = albums_text.split('||')

last_disk_not_found = 0

albums.each do |album_str|
  album = album_str.split('|')

  disk = album[3].to_s.rjust(3, '0')

  path = getDiskPath(disk)

  if path == ''

    if last_disk_not_found != disk
      last_disk_not_found = disk
      puts "DISK NOT FOUND: " + disk
    end

  else
    m3uText = ''
    arrOfFiles = []

    albumDir = album[1]+' - '+album[2]
    pathToAlbum = path + "\\" + albumDir

    if !FileTest.directory?(pathToAlbum)
      puts "ALBUM NOT FOUND: " + pathToAlbum;
    else
      puts pathToAlbum

      prefix = getPrefix(path) + disk + "\\"
      Find.find(pathToAlbum) do |filePath|
        if FileTest.directory?(filePath)
          next
        end

        pn = Pathname.new(filePath)

        if pn.extname() != '.mp3' && pn.extname() != '.flac'
          next
        end

        arrOfFiles << prefix + albumDir + "\\" + pn.basename().to_s
      end

      arrOfFiles = arrOfFiles.sort
      arrOfFiles.each do |fname|
        m3uText += fname + "\r\n"
      end


      if !m3uText.empty?
        postit = Net::HTTP.post_form(URI.parse('http://www.vzasade.com/mdb/pages/set_playlist_int.php'), {'action'=>'store', 'info'=>m3uText, 'row_id'=>album[0]})
        puts postit.body
      end
    end
  end
end
