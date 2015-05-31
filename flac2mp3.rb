require 'rubygems'
require 'net/http'
require 'fileutils'
require 'find'
require 'uri'
require 'taglib'
require File.dirname(__FILE__) + '/../deployment/http_proxy.rb'
require File.dirname(__FILE__) + '/mdb_common.rb'

$wav_dir = ENV["MUSIC_TEMP_DIR"] + '\wav'
$mp3_dir = ENV['MUSIC_TEMP_DIR'] + '\mp3'
$flac_path = "\"" + ENV['FLAC_PATH'] + "\""
$lame_path = "\"" + ENV['LAME_PATH'] + "\""

def createDir(path)
  if FileTest.directory?(path)
    return
  end
  puts "Creating directory " + path
  FileUtils.mkdir_p(path)
end

createDir($wav_dir)

def getAlbumId(alb_name)
  alb = dirName2Album(alb_name)
  album = alb["artist"] + " - " + alb["name"]

  artist = URI.escape(alb["artist"], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  name = URI.escape(alb["name"], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

  url = "/mdb/pages/get_album_id.php?artist=" + artist + "&name=" + name
  #puts url

  alb_id = nil
  httpStartWithProxy ("www.vzasade.com") do |http|
    reply = http.get(url)
    if (Net::HTTPSuccess === reply)
      alb_id = reply.body.to_s
    else
      puts reply
    end
  end
  #  id = Net::HTTP.get URI.parse(url)

  #puts "[[" + id + "]]"

  if alb_id == ""
    puts "Album " + album + " not found."
    return nil
  end

  return alb_id
end

def getPictureUrl(id)
  url = "/mdb/pages/get_cover.php?row_id=" + id
  picurl = nil
  httpStartWithProxy ("www.vzasade.com") do |http|
    reply = http.get(url)
    if (Net::HTTPSuccess === reply)
      picurl = reply.body.to_s
    else
      puts reply
    end
  end

  if picurl == ""
    return nil
  end

  puts picurl

  return picurl
end

def downloadPicture(dir, alb_name)
  filePath = dir + "\\mdb_cover.jpg";

  if File.exists?(filePath)
    puts "Picture is already downloaded"
    return filePath
  end

  id = getAlbumId(alb_name)
  if id ==  nil
    puts "Picture not found"
    exit(1)
  end
  url = getPictureUrl(id)

  httpStartWithProxy ("www.vzasade.com") do |http|
    resp = http.get(url)

    index = resp.body.index("400 Bad Request")
    if index != nil
      puts "Can not download picture"
      exit (-1)
    end

    open(filePath, "wb") do |file|
      file.write(resp.body)
    end
    puts "Picture downloaded"
  end
  return filePath
end

def executeCommand(command)
  if !system(command)
    puts "Failed to execute command: " + command
    exit(0)
  end
end

def decodeFlacFile(inpath, outpath)
  executeCommand($flac_path + " -d -f -o \"" + outpath + "\" \"" + inpath + "\"")
end

def encodeMp3File(inpath, outpath)
  executeCommand($lame_path + " -V0 -b192 -B320 -F -q0 --replaygain-accurate \"" + inpath + '" "' + outpath + '"')
end

def createMp3Dir(dir)
  path = $mp3_dir + "\\" + dir
  createDir(path)
  return path
end

def createWav3Dir(dir)
  path = $wav_dir + "\\" + dir
  createDir(path)
  return path
end

def processDir(path)
  albumDir = getLastPathElem(path)
  puts "Processing Album: " + albumDir

  mp3DirPath = createMp3Dir(albumDir)

  picturePath = downloadPicture(path, albumDir)

  Find.find(path) do |subdirPath|
    if FileTest.directory?(subdirPath)
      next
    end

    filePath = subdirPath.gsub('/', '\\')

    fileFullName = getLastPathElem(filePath)
    fileExt = getExt(fileFullName)
    fileName = getFileName(fileFullName)

    mp3Path = nil

    if (fileExt == 'mp3')
      puts "Processing: " + fileFullName;
      mp3Path = mp3DirPath + "\\" + fileFullName

      FileUtils.cp filePath, mp3Path
    end

    if (fileExt == 'flac')
      puts "Processing: " + fileFullName;
      mp3Path = mp3DirPath + "\\" + fileName + ".mp3"

      #wavPath = createWav3Dir(albumDir) + "\\" + fileName + ".wav"
      wavPath = $wav_dir + "\\tmp.wav"
      FileUtils.rm wavPath, :force => true

      decodeFlacFile(filePath, wavPath)
      encodeMp3File(wavPath, mp3Path)

      TagLib::FileRef.open(filePath) do |fileref|
        tag = fileref.tag
        printTag(tag)
        saveTagToMp3(mp3Path, tag)
      end
    end

    if mp3Path != nil
      attachPictureToMp3Tag(mp3Path, picturePath)
    end

  end

  exit(0)
end

def attachPictureToMp3Tag(filePath, picture)
  if picture != nil
    TagLib::MPEG::File.open(filePath) do |file|
      tag = file.id3v2_tag
      cover = TagLib::ID3v2::AttachedPictureFrame.new

      cover.mime_type = 'image/jpeg'
      cover.type = 30
      cover.description = 'Cover'
      cover.text_encoding = 0
      cover.picture = open(picture, "rb") {|io| io.read }
      tag.add_frame(cover)

      file.save
    end
  end
end

def saveTagToMp3(filePath, flacTag)
  TagLib::FileRef.open(filePath) do |fileref|
    fileref.tag.artist = flacTag.artist
    fileref.tag.album = flacTag.album
    fileref.tag.title = flacTag.title
    fileref.tag.year = flacTag.year
    fileref.tag.genre = flacTag.genre
    fileref.tag.track = flacTag.track
    fileref.save
  end
end

def printTag(tag)
  puts "Writing tag:"
  puts "ARTIST: [" + tag.artist + "]"
  puts "ALBUM: [" + tag.album + "]"
  puts "TITLE: [" + tag.title + "]"
  puts "YEAR: [" + tag.year.to_s + "]"
  puts "GENRE: [" + tag.genre + "]"
  puts "TRACK: [" + tag.track.to_s + "]"
end


######################################################
# Body
######################################################

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  puts 'USAGE: flac2mp3.rb <path to album dir>'
  exit -1
end

dir_to_convert = ARGV[0]

processDir(dir_to_convert)
