require 'rubygems'
require 'net/http'
require File.dirname(__FILE__) + '/mdb_common.rb'
require File.dirname(__FILE__) + '/upload.rb'

def processDir(path)
  album = processAlbum(path)

  x = Net::HTTP.post_form(URI.parse('http://www.vzasade.com/mdb/pages/api_create_album.php'), album)

  body = x.body
  update = false;

  if body.start_with?('U.')
    update = true
    body = body.slice('U.'.length, body.length - 'U.'.length)
  end

  if body.start_with?('row_id:')
    body = body.slice('row_id:'.length, body.length - 'row_id:'.length)
    puts "Album ID: " + body
    if update
      puts "Album updated. ID=" + body
    else
      puts "Album created. ID=" + body
      uploadPictures(body)
    end

    if ENV['BROWSER'] != nil
      exec("\"" + ENV['BROWSER'] + "\" \"http://vzasade.com/mdb/pages/main.php?row_id=" + body + "\"");
    end
  else
    puts "ERROR: " + body
  end

  exit(0)

end

######################################################
# Body
######################################################

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  puts 'USAGE: create_album.rb <path to album dir>'
  exit -1
end

processDir(ARGV[0])
