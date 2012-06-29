#!/usr/bin/ruby -I../.. -rmagic_xml

XML.bib! {
    XML.load('bib.xml').children(:book) {|b|
        next unless b.children(:author).size > 0
        book! {
            add! b.children(:title)
            authors = b.children(:author)
            add! authors[0,2]
            xml!(:"et-al") if authors.size > 2
        }
    }
}
