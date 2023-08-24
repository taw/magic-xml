#!/usr/bin/env ruby

require "magic_xml"

XML.result!(
    XML.load('sgml.xml').descendants(:chapter)[1].descendants(:section)[2].descendants(:para)[1]
)
