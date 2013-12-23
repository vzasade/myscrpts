require 'rubygems'

$flac_path = "\"" + ENV['FLAC_PATH'] + "\""
$mac_path = "\"" + ENV['MAC_PATH'] + "\""

def stripExt(nameWithExt)
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

def executeCommand(command)
  if !system(command)
    puts "Failed to execute command: " + command
    exit(0)
  end
end


def encodeFlacFile(inpath, outpath)
  executeCommand($flac_path + " --best -f -o \"" + outpath + "\" \"" + inpath + "\"")
end  

def decodeApeFile(inpath, outpath)
  executeCommand($mac_path + " \"" + inpath + "\" \"" + outpath + "\" -d")
end  

def processFile(path)
  puts("Processing: " + path)
   pathWithoutExt = stripExt(path)
   decodeApeFile(path, pathWithoutExt + ".wav")
   encodeFlacFile(pathWithoutExt + ".wav", pathWithoutExt + ".flac")
   File.delete(path)
   File.delete(pathWithoutExt + ".wav")
end

def processDir(path)
  Dir.chdir(path)
  Dir.glob('**/*.ape').sort.each do |f|
    processFile(path + "/" + f)
  end
end


######################################################
# Body
######################################################

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  puts 'USAGE: flac2mp3.rb <path to album dir>'
  exit -1
end

processDir(ARGV[0])
