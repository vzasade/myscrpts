if __FILE__ == $0
  # TODO Generated stub
end

def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
end


require 'rubygems'
suppress_warnings{require 'FileUtils'}
require 'find'

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  puts 'USAGE: explode.rb <archive> <dest_dir>'
  exit -1
end

dest_dir = ARGV[0].dup

def iterateThroughFiles( dirname )
  Find.find( dirname ) do | thisfile |
    thisfile.gsub!( /\\/ , '/' )
    yield(thisfile)
  end
end

file_list = Array.new

dest_dir.gsub!( /\\/ , '/' )
iterateThroughFiles(dest_dir) do |path|
   if path.start_with? dest_dir
      path = path[dest_dir.length, path.length]
   end
   file_list.push path
end

file_list = file_list.sort

file_list.each do |path|
   puts path
end
