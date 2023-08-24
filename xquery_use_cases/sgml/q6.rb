#!/usr/bin/env ruby

require "magic_xml"

XML.result! {
    XML.load('sgml.xml').descendants(:section).each{|s|
        stitle! s[:shorttitle]
    }
}
