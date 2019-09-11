require 'rubygems'

$sox_path = "\"" + ENV['SOX_PATH'] + "\""

def executeCommand(command)
  if !system(command)
    puts "Failed to execute command: " + command
    exit(0)
  end
end

def processFile(path)
  puts("Processing: " + path)
  pathWithoutExt = File.join(File.dirname(path), File.basename(path, File.extname(path)))
  executeCommand($sox_path + " \"" + path + "\" -b 24 -r 48000 \"" + pathWithoutExt + "_x.wav\"")
end

def processDir(path)
  Dir.chdir(path)
  Dir.glob('**/*.{ape,wv,flac,wav}').sort.each do |f|
    processFile(path + "/" + f)
  end
end

######################################################
# Body
######################################################

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  puts 'USAGE: hrc.rb <path to album dir>'
  exit -1
end

processDir(ARGV[0])
