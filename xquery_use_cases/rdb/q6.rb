#!/usr/bin/env ruby -I../../lib -rmagic_xml

items = XML.load('items.xml')
bids  = XML.load('bids.xml')

XML.result! {
    items.each(XML){|item|
# z can be nil if there are no bids
        z = bids.find_all{|b| b.is_a? XML and b[:@itemno] == item[:@itemno]}.map{|b| b[:@bid].to_i}.max
        next unless z and item[:@reserve_price].to_i * 2 < z
        successful_item! {
            add! item.child(:itemno)
            add! item.child(:description)
            add! item.child(:reserve_price)
            high_bid! z
        }
    }
}
