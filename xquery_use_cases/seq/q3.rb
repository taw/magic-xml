#!/usr/bin/ruby -I../.. -rmagic_xml

doc = XML.load('report1.xml')
i2 = doc.descendants(:incision)[1]

print doc.range(i2,nil).descendants(:action)[0,2].children(:instrument)
