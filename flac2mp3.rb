require 'rubygems'
require 'net/http'
require 'fileutils'
require 'find'
require 'uri'
require 'taglib'
require File.dirname(__FILE__) + '/mdb_common.rb'

$music_temp_dir = ENV["MUSIC_TEMP_DIR"] ? ENV["MUSIC_TEMP_DIR"] : "/tmp"

$wav_dir = File.join($music_temp_dir, "wav")
$mp3_dir = File.join($music_temp_dir, "mp3")
$flac_path = ENV['FLAC_PATH'] ? "\"" + ENV['FLAC_PATH'] + "\"" : "flac"
$lame_path = ENV['LAME_PATH'] ? "\"" + ENV['LAME_PATH'] + "\"" : "lame"

def ensureDir(path)
  unless FileTest.directory?(path)
    puts "Creating directory " + path
    FileUtils.mkdir_p(path)
  end
end

ensureDir($wav_dir)

def apiGet(http, url)
  request = Net::HTTP::Get.new(url)
  response = http.request(request)

  Net::HTTPSuccess === response or abort "Failed to retrirve " + yield

  # the api has to be changed to issue correct code
  response.body.to_s != "" or abort yield + " not found."

  return response.body.to_s
end

def queryAlbumId(http, artist, name)
  artistEsc = URI.escape(artist, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  nameEsc = URI.escape(name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

  apiGet(http, "/mdb/pages/get_album_id.php?artist=" + artistEsc + "&name=" + nameEsc) do
    "album " + artist + " - " + name
  end
end

def getPictureUrl(http, id)
  apiGet(http, "/mdb/pages/get_cover.php?row_id=" + id) do
    "picture for " + id
  end
end

def downloadFile(http, url, path)
  resp = http.get(url)
  resp.code < "300" or abort "Cannot download file from " + url

  open(path, "wb") do |file|
    file.write(resp.body)
  end
end

def downloadPicture(dir, albName)
  path = File.join(dir, "mdb_cover.jpg")
  alb = dirName2Album(albName)

  if File.exists?(path)
    puts "Picture is already downloaded"
    return path
  end

  Net::HTTP.start("www.vzasade.com") do |http|
    id = queryAlbumId(http, alb["artist"], alb["name"])

    url = getPictureUrl(http, id)
    downloadFile(http, url, path)

    puts "Picture downloaded to " + path
    path
  end
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
  ensureDir(path)
  return path
end

def createWav3Dir(dir)
  path = $wav_dir + "\\" + dir
  ensureDir(path)
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
