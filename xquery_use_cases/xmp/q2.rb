#!/usr/bin/env ruby

require "magic_xml"

XML.results! {
    XML.load('bib.xml').children(:book) {|b|
        t = b.child(:title)
        b.children(:author) {|a|
            result!(t,a)
        }
    }
}
