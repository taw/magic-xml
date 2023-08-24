#!/usr/bin/env ruby

require "magic_xml"

doc = XML.load('book.xml')

XML.section_count!(doc.descendants(:section).size)
XML.figure_count!(doc.descendants(:figure).size)
