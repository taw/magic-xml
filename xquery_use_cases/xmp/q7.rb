#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.bib! {
    XML.load('bib.xml').children(:book).find_all{|b|
        b[:@publisher] == "Addison-Wesley" and
        b[:year].to_i > 1991
    }.sort_by{|b| b[:@title] }.each {|b|
        book!({:year => b[:year]}, b.child(:title))
    }
}
