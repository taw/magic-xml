#!/usr/bin/ruby -I../../lib -rmagic_xml

puts XML.result(XML.load('sgml.xml').descendants(:intro, :para))
