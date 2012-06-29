#!/usr/bin/ruby -I../.. -rmagic_xml

XML.results! {
    XML.load('bib.xml').children(:book) {|b|
        result!(b.children(:title), b.children(:author))
    }
}
