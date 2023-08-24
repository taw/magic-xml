#!/usr/bin/env ruby

require "magic_xml"

XML.load('bib.xml').children(:book) {|b|
    b.descendants {|e|
        if e.is_a? XML and e =~ /Suciu/ and e.name.to_s =~ /or$/
            XML.book!(b.child(:title), e)
        end
    }
}
