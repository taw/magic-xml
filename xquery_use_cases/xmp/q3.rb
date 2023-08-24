#!/usr/bin/env ruby

require "magic_xml"

XML.results! {
    XML.load('bib.xml').children(:book) {|b|
        result!(b.children(:title), b.children(:author))
    }
}
