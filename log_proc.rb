if __FILE__ == $0
  # TODO Generated stub
end

#regex test: http://rubular.com/

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  exit -1
end

input_file = ARGV[0]


def processLine(line)
   line = line.gsub(/\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}-\d{2}:\d{2}\]/, '')
   line = line.gsub(/\[tid: \[[^\]]+\][^\]]+\]/, '')
   line = line.gsub(/\[ecid:[^\]]+\]/, '')
   line = line.gsub(/\[userId:[^\]]+\]/, '')
   line = line.gsub(/[a-zA-Z0-9]+![0-9]+![0-9]+/, '<SID>')
   return line
end

counter = 1
file = File.new(input_file, "r")
while (line = file.gets)
   line = processLine(line)
   puts line
   counter = counter + 1
end
file.close

