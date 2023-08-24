#!/usr/bin/env ruby

require "magic_xml"

XML.results! {
    doc = XML.load('bib.xml')
    a = doc.descendants(:author)
    books = doc.children(:book)

    a.map{|node|
        [node[:@last], node[:@first]]
    }.uniq.sort.each {|last, first|
        result! {
            author! {
                last! last
                first! first
            }
            books.each{|b|
                next unless b.children(:author).any?{|ba|
                    ba[:@last] == last and ba[:@first] == first
                }
                add! b.children(:title)
            }
        }
    }
}
