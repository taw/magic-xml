#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.top_section_count!(XML.load('book.xml').children(:section).size)
