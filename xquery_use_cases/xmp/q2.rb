#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.results! {
    XML.load('bib.xml').children(:book) {|b|
        t = b.child(:title)
        b.children(:author) {|a|
            result!(t,a)
        }
    }
}
