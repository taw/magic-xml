#!/usr/bin/ruby -I../.. -rmagic_xml

items = XML.load('items.xml')
bids  = XML.load('bids.xml')

highbid = bids.children.children(:bid).map{|b| b.text.to_i}.max.to_s

XML.result! {
    items.each(XML){|item|
        bids.each({:@itemno => item[:@itemno], :@bid => highbid}) {|b|
            expensive_item! {
                add! item.child(:itemno)
                add! item.child(:description)
                high_bid! highbid
            }
        }
    }
}
