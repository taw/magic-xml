#!/usr/bin/ruby -I../.. -rmagic_xml

items = XML.load('items.xml')
bids = XML.load('bids.xml')

XML.result!{
    items.each(XML){|i|
        next if bids.any?{|b| b.is_a? XML and b[:@itemno] == i[:@itemno]}
        no_bid_item!(i.child(:itemno), i.child(:description))
    }
}
