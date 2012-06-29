#!/usr/bin/ruby -I../.. -rmagic_xml

puts XML.result(XML.load('sgml.xml').descendants(:intro, :para))
