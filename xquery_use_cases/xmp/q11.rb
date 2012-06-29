#!/usr/bin/ruby -I../.. -rmagic_xml

XML.bib! {
    doc = XML.load('bib.xml')

    doc.children(:book) {|b|
        if b.children(:author).size != 0
            book!(b.children(:title), b.children(:author))
        end
    }

    doc.children(:book) {|b|
        if b.children(:editor).size != 0
            reference!(b.children(:title), b.children(:editor).children(:affiliation))
        end
    }
}
