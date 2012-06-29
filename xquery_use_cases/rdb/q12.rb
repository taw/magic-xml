#!/usr/bin/ruby -I../.. -rmagic_xml

items = XML.load('items.xml')
bids  = XML.load('bids.xml').children(:bid_tuple)

# XML should work as a Hash key !
XML.result! {
    bids_per_item = Hash.new([])
    bids.each{|bid|
        bids_per_item[bid[:@itemno]] += [bid]
    }
    max_bid_count = bids_per_item.map{|k,v| v.size}.max

    items.each(XML){|item|
        next unless bids_per_item[item[:@itemno]].size == max_bid_count
        popular_item! {
            add! item.child(:itemno)
            add! item.child(:description)
            bid_count! max_bid_count
        }
    }
}
