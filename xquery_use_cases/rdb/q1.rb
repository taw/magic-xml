#!/usr/bin/ruby -I../../lib -rmagic_xml

current_day = "1999-01-31"

items = XML.load('items.xml').sort_by{|i| i[:@itemno].to_i}
XML.result! {
    items.each(XML) {|i|
        next unless current_day.between?(i[:@start_day], i[:@end_day]) and i[:@description] =~ /Bicycle/
        item_tuple!(i.children(:itemno), i.children(:description))
    }
}
