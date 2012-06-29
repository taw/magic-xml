#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.result!(XML.load('sgml.xml').descendants(:para).find_all{|p| p[:security] == 'c'})
