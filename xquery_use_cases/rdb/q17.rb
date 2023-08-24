#!/usr/bin/env ruby

require "magic_xml"

users = XML.load('users.xml')
items = XML.load('items.xml')
bids  = XML.load('bids.xml')

XML.frequent_bidder! {
    users.each(XML){|u|
        next unless items.all?{|item|
            (!item.is_a? XML) or
            bids.any?{|b| b.is_a? XML and item[:@itemno] == b[:@itemno] and u[:@userid] == b[:@userid]}
        }
        add! u.child(:name)
    }
}
