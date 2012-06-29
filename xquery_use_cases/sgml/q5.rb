#!/usr/bin/ruby -I../.. -rmagic_xml

XML.result!(XML.load('sgml.xml').descendants(:para).find_all{|p| p[:security] == 'c'})
