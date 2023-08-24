#!/usr/bin/env ruby -I../../lib -rmagic_xml

XML.bib! {
    books = XML.load('bib.xml').children(:book)
    books.each_with_index{|book1, i|
        aut1 = book1.children(:author).map{|a| [a[:@last], a[:@first]]}.sort

        books.each_with_index{|book2, j|
            next unless i < j and book1[:@title] != book2[:@title]
            aut2 = book2.children(:author).map{|a| [a[:@last], a[:@first]]}.sort

            xml!(:"book-pair", book1.child(:title), book2.child(:title)) if aut1 == aut2
        }
    }
}
