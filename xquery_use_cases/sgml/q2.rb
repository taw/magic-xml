#!/usr/bin/env ruby

require "magic_xml"

puts XML.result(XML.load('sgml.xml').descendants(:intro, :para))
