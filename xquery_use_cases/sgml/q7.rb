#!/usr/bin/env ruby

require "magic_xml"

XML.result! {
    XML.load('sgml.xml').descendants(:intro) {|i|
        first_letter! i.children(:para)[0].text[0,1]
    }
}
