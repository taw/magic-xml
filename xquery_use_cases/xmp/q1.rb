#!/usr/bin/env ruby

require "magic_xml"

XML.bib! {
    XML.load('bib.xml').children(:book) {|b|
        if b[:@publisher] == "Addison-Wesley" and b[:year].to_i > 1991
            book!({:year => b[:year]}, b.child(:title))
        end
    }
}
