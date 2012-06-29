#!/usr/bin/ruby -I../.. -rmagic_xml

users = XML.load('users.xml')
bids  = XML.load('bids.xml').sort_by{|b| b[:@itemno].to_i}

XML.result! {
    bids.each{|highbid|
        next if bids.any?{|b| b[:@itemno] == highbid[:@itemno] and b[:@bid].to_i > highbid[:@bid].to_i}
        users.children({:@userid => highbid[:@userid]}){|user|
            high_bid! {
                add! highbid.child(:itemno)
                add! highbid.child(:bid)
                bidder! user[:@name]
            }
        }
    }
}
