require 'rubygems'
require 'RMagick'

if __FILE__ == $0
  # TODO Generated stub
end

if ARGV.length != 1
  puts 'Incorrect number of arguments!'
  exit -1
end

$sub_dir = ARGV[0]

$root_dir = ENV['BLOG_SRC']
if $root_dir == nil
  $root_dir = 'D:\Work'
end

$blog_root = 'http://blogs.oracle.com/ensemble/resource/'

$input_file = File.join($root_dir, $sub_dir, "src.txt")

def getFileEntry(name)
  img = Magick::Image::read(File.join($root_dir, $sub_dir, name)).first
  rows = img.rows
  cols = img.columns

  if rows > cols
    t_rows = 250
    t_cols = (cols * 250) / rows
  else
    t_cols = 250
    t_rows = (rows * 250) / cols
  end
  
  rows = rows + 20
  cols = cols + 20
  
  url = $blog_root + $sub_dir + "/" + name
  entry = "<a href=\"" + url + "\" target=\"" + name + "\" onclick=\"window.open(&quot;" + url + "&quot;, &quot;" + name + "&quot;, "
  entry += "&quot;height=" + rows.to_s() + ",width=" + cols.to_s() + ",menubar=no,status=no,toolbar=no&quot;); return false;\">\n"
  entry += "<img border=\"0\" align=\"absmiddle\" style=\"height: " + t_rows.to_s() + "px; width: " + t_cols.to_s() + "\" "
  entry += "src=\"" + url +"\" /></a>"
end

def replacePictures(line)
  return line.gsub(/!.*\.jpg\|thumbnail!/) do |match|
    name = match.slice(1, match.length - 12)
    getFileEntry(name)
  end
end

class TextStyle
  def initialize(symbol, tag)
    @symbol = symbol
    @tag = tag
    @on = false
  end
  
  def processSymbol(c)
    if (c == @symbol)
      if @on
        @on = false
        return "</" + @tag + ">"
      else
        @on = true
        return "<" + @tag + ">"
      end
    end
    return nil;
  end
end

class HtmlLine
  def initialize(line)
    @line = line
  end
  
  def formatLine(line)
    newstr = ""
    escape = false
    
    line.each_byte do |f|
      i = f.chr
      if escape
        newstr += i
        escape = false
        next
      end
      
      if i == '\\'
        escape = true
        next
      end
      
      newstr += i
    end
    return newstr
  end
  
  def render
    line = replacePictures(@line)
    
    #local urls
    line  = line.gsub(/http:\/\/\S*\.company\.com\S*/) do |match|
      "<u><b>" + match + "</b></u>"
    end
    
    #bold
    line  = line.gsub(/(\A|\W|_)\*(\S[^*]*\S)\*(\W|_|\z)/) do |match|
      $1 + "<b>" + $2 + "</b>" + $3
    end
    
    #italic
    line  = line.gsub(/(\A|\W)_(\S[^_]*\S)_(\W|\z)/) do |match|
      $1 + "<i>" + $2 + "</i>" + $3
    end
    
    #underline
    line  = line.gsub(/(\A|\W|_)\+(\S[^+]*\S)\+(\W|_|\z)/) do |match|
      $1 + "<u>" + $2 + "</u>" + $3
    end
    
    #strike
    line  = line.gsub(/(\A|\W|_)-(\S[^-]*\S)-(\W|_|\z)/) do |match|
      $1 + "<s>" + $2 + "</s>" + $3
    end

    #escapes
    line = formatLine(line)
    puts line
  end

  def processLine(line)
    return false
  end
end

class HtmlGroup
  def initialize
    @items = Array.new
    @insertbreaks = false
  end
  
  def render
    needbreak = false
    @items.each do |x| 
        if needbreak
          puts "<br />"
        end
      x.render
      if @insertbreaks
        needbreak = true
      end
    end
  end

  def processLine(line)
    if @items.length > 0
      if @items[@items.length - 1].processLine(line)
        return true
      end
    end
    return false
  end
end

class HtmlListItem < HtmlGroup
  def initialize(line)
    super()
    @items.push(HtmlLine.new(line))
    @insertbreaks = true
  end

  def render
    if @items.size > 0
      puts "\n<li>"
      super
      puts "\n</li>"
    end
  end
  
  def processLine(line)
    @items.push(HtmlLine.new(line))
    return true;
  end
  
end

class HtmlList < HtmlGroup
  def initialize(style)
    super()
    @style = style
    @closed = false
  end
  
  def render
    if @items.size > 0
      puts "\n<ul>"
      super()
      puts "\n</ul>"
    end
  end
  
  def processLine(line)
    if @closed
      return false
    end
    
    style = @style + " "
    
    if line.index(style) == 0
      line = line.slice(style.length, line.length - style.length)
      line.lstrip!
      @items.push(HtmlListItem.new(line))
      return true
    end
    
    if line.empty?
      @closed = true
      return false
    end
    
    style = @style + "* "

    if (line.index(style) == 0) && (@style.length < 3)
      list = HtmlList.new(@style + "*")
      if list.processLine(line)
        @items.push(list)
        return true
      end
    end

    if super(line)
      return true
    end
    return false
  end
end

class HtmlParagraph < HtmlGroup
  def initialize(style)
    super()
    @closed = false
    @insertbreaks = true
  end
  
  def render
    if @items.size > 0
      puts "<p>"
      super()
      puts "</p>"
    end
  end
  
  def processLine(line)
    if @closed
      return false
    end
  
    if line.empty?
      @closed = true
      return false
    end
  
    @items.push(HtmlLine.new(line))
    return true;
  end
end


class HtmlTag
  def initialize(tag, content, args)
    @tag = tag
    @content = content
    @args = args
  end
  
  def render
    args = ""
    if @args.length > 0
      args = " " + @args
    end
    puts "<" + @tag + args + ">" + @content + "</" + @tag + ">"
  end
  
  def processLine(line)
    return false
  end
end
 

class HtmlScript < HtmlGroup
  def initialize
    super
  end
  
  def processHeader(line, style, tag, args)
    line.strip!
    
    if line.index(style) == 0
      line = line.slice(style.length, line.length - style.length)
      line.lstrip!
      @items.push(HtmlTag.new(tag, line, args))
      return true
    end
    return false
  end
    
  def processLine(line)
    line.strip!

    if processHeader(line, "h3.", "h3", "style=\"background-color: #c3c3c3;\"")
      return
    end

    if super(line)
      return true
    end
    
    if line.index("*") == 0
      list = HtmlList.new("*")
      if list.processLine(line)
        @items.push(list)
        return true
      end
    end
    
    paragraph = HtmlParagraph.new(line)
    if paragraph.processLine(line)
      @items.push(paragraph)
    end
    
    return false;
  end
end

file = File.new($input_file, "r")
script = HtmlScript.new
while (line = file.gets)
   script.processLine(line)
end
script.render
file.close
