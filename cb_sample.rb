require 'rubygems'
require 'couchbase'

client = Couchbase.connect(:bucket => "beer-sample",
                           :hostname => "localhost")

puts client.method(:get).inspect

beer = client.get("aass_brewery-juleol")
puts "#{beer['name']}, ABV: #{beer['abv']}"

ddoc = client.design_docs["beer"]
puts ddoc

ddoc.brewery_beers.each do |row|
  puts "KEY=#{row.key}"
  puts "VALUE=#{row.value}"
  puts "ID=#{row.id}"
  puts "DOC=#{row.doc}"
end

exit()

# 2: Query the view and use results
ddoc.beers_by_category(:keys => ["North American Ale"]).each do |row|
  puts "KEY=#{row.key}"
  #puts "VALUE=#{row.value}"
  #puts "ID=#{row.id}"
  #puts "DOC=#{row.doc}"
  puts "DOC.name=#{row.value["name"]}"
  #puts row.methods
  #break
end

#beer['comment'] = "Random beer from Norway"
#client.replace("aass_brewery-juleol", beer)

client.disconnect