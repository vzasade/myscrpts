require 'net/http'
require 'uri'
require 'find'

def getOneDiskPath(drive,disk)
  return drive+':\\jukebox\\'+disk;
end

def getDiskPath(disk)
  drives = ['D','J','Z']

  for drive in drives
    path = getOneDiskPath(drive,disk)
    
    if (FileTest.directory?(path))
      return path
    end
  end
  return ''
end

  
albums_text = Net::HTTP.get URI.parse('http://www.vzasade.com/mdb/pages/no_playlist_int.php') 

albums = albums_text.split('||')

last_disk_not_found = 0

albums.each do |album_str|
  album = album_str.split('|')
  
  disk = album[3].to_s;
  
  while disk.length < 3 do
    disk = '0' + disk
  end

  path = getDiskPath(disk)
  
  if path == ''
  
    if last_disk_not_found != disk
      last_disk_not_found = disk
      puts "DISK NOT FOUND: " + disk
    end
    
  else
    m3uText = ''
    arrOfFiles = []
    
    pathToAlbum = path+"\\"+album[1]+' - '+album[2]
    
    if !FileTest.directory?(pathToAlbum)
      puts "ALBUM NOT FOUND: " + pathToAlbum;
    else
      puts pathToAlbum

      Find.find(pathToAlbum) do |filePath|
        if FileTest.directory?(filePath) 
          next
        end
        
        
        if filePath.slice(filePath.length - 4, 4) != '.mp3' && filePath.slice(filePath.length - 5, 5) != '.flac'
          next
        end

        filePath = filePath.gsub('/', '\\')
        filePath = filePath.gsub('D:\\', 'g:\\')
        arrOfFiles << filePath.gsub('D:\\', 'G:\\')
      end

      arrOfFiles = arrOfFiles.sort
      arrOfFiles.each do |fname|
        m3uText += fname + "\r\n"
      end
      
      
      if !m3uText.empty?
        postit = Net::HTTP.post_form(URI.parse('http://www.vzasade.com/mdb/pages/set_playlist_int.php'), {'action'=>'store', 'info'=>m3uText, 'row_id'=>album[0]})

        locPath = 'j:\\playlists\\' + disk
        Dir.mkdir(locPath) unless File.exists?(locPath)
        
        #create file in j:\playlists
        locPath = 'j:\\playlists\\' + disk + '\\' +album[1]+' - '+album[2]+'.m3u'
        File.open(locPath, 'w') do |f2|  
          f2.puts(m3uText)
        end
        
        #puts postit.body      
        #puts m3uText
      end
    end
  end
end
