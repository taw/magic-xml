#!/usr/bin/ruby -I../.. -rmagic_xml

XML.load('string.xml').descendants(:news_item) {|item|
    next unless item =~ /Gorilla Corporation/
    XML.item_summary! {
# Whitespace is wrong without .strip
        add! item[:@title].strip
        add! ". "
        add! item[:@date]
        add! ". "
        add! item.descendants(:par)[0].text
    }
}
