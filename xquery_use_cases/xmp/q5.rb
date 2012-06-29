#!/usr/bin/ruby -I../../lib -rmagic_xml

# dash in tag names forces us to use
# a bit less convenient methods.
xml!(:"books-with-prices") {
    books = XML.load("bib.xml").descendants(:book)
    entries = XML.load("reviews.xml").descendants(:entry)
    books.each{|b|
        entries.each{|a|
            next unless a[:@title] == b[:@title]
            xml!(:"book-with-prices") {
                add! b.child(:title)
                xml!(:"price-bstore2", a[:@price])
                xml!(:"price-bstore1", b[:@price])
            }
        }
    }
}
