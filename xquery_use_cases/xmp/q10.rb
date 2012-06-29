#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.results! {
    doc = XML.load('prices.xml')
    doc.children(:book).children(:title).map{|node| node.text}.uniq.each{|title|
        minprice!({:title => title}) {
            price! {
                text! doc.children(:book).find_all{|book|
                          book[:@title] == title
                      }.map{|book|
                          book[:@price].to_f 
                      }.min
            }
        }
    }
}
