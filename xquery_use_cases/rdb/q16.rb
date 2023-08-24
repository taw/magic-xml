#!/usr/bin/env ruby -I../../lib -rmagic_xml

users = XML.load('users.xml').sort_by{|i| i[:@userid].to_i}
bids  = XML.load('bids.xml')

XML.result! {
    users.each(XML){|u|
        user_bids = bids.children({:@userid => u[:@userid]})
        user! {
            add! u.child(:userid)
            add! u.child(:name)
            status! (user_bids.empty? ? 'inactive' : 'active')
        }
    }
}
