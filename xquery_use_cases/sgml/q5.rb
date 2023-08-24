#!/usr/bin/env ruby

require "magic_xml"

XML.result!(XML.load('sgml.xml').descendants(:para).find_all{|p| p[:security] == 'c'})
