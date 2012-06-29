#!/usr/bin/ruby -I../../lib -rmagic_xml

items = XML.load('items.xml').sort_by{|i| i[:@itemno].to_i}
users = XML.load('users.xml')
bids  = XML.load('bids.xml')

# Use pseudoattribute selectors for selects.
XML.result! {
    users.each({:@name => "Tom Jones"}) {|seller|
        items.each({:@offered_by => seller[:@userid], :@description => /Bicycle/}) {|item|
            bids.each({:@itemno => item[:@itemno]}) {|highbid|
                users.each({:@userid => highbid[:@userid]}) {|buyer|
                    best_bid = bids.find_all{|b| b.is_a? XML and b[:@itemno] == item[:@itemno]}.map{|b| b[:@bid].to_i}.max
                    next unless highbid[:@bid].to_i == best_bid
                    
                    jones_bike! {
                        add! item.child(:itemno)
                        add! item.child(:description)
                        high_bid! highbid.child(:bid)
                        high_bidder! buyer.child(:name)
                    }
                }
            }
        }
    }
}
