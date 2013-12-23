$start_index = 1001
$end_index = 2500
$interval = 50
$items_in_line=10

dir = "C:\\Work\\mdb\\catalog\\"

def getInterval(start)
  return start.to_s() << "-" << (start + $interval - 1).to_s()
end


def getPageName(start)
  if start == 1001
    return "ECM"
  end
  
  return "ECM." << getInterval(start)
end

def genHeader(current)
  s = ""
  i = $start_index
  item=1
  while i <= $end_index
    if i == current
      s << "<b>"
    end
    
    s << "[[page=" << getPageName(i)
    s << '|title=' << getInterval(i) << "]]"

    if i == current
      s << "</b>"
    end
    s << "\n"
    
    if item == $items_in_line
      s << "<br>"
      item = 0
    end
    
    
    item = item + 1
    i = i + $interval
  end
  return s
end

i = $start_index
while i <= $end_index
  pagename = getPageName(i)
   
  file = File.open(dir + pagename+ ".txt", "w")
  file.puts("<b>ECM Catalog:</b><br>")
  file.puts(genHeader(i))
  file.puts("<br>")
  
  file.puts("[[cat=ECM|num=" + getInterval(i) + "|title=ECM " + getInterval(i) + "]]")
  file.close
  
  i = i + $interval
end

  
#file = File.open("temp.txt", "w")

