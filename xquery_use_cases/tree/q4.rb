#!/usr/bin/env ruby

require "magic_xml"

XML.top_section_count!(XML.load('book.xml').children(:section).size)
