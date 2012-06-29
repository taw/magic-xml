#!/usr/bin/ruby -I../../lib -rmagic_xml

items = XML.load('items.xml').sort_by{|i| i[:@itemno].to_i}
bids  = XML.load('bids.xml')

XML.result! {
    items.each({:@description => /Bicycle/}){|i|
        item_tuple! {
            add! i.children(:itemno)
            add! i.children(:description)

            item_bids = bids.find_all{|b| b.is_a? XML and b[:@itemno] == i[:@itemno] }
            high_bid! item_bids.map{|b| b[:@bid].to_i}.max
        }
    }
}
