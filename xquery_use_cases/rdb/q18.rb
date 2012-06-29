#!/usr/bin/ruby -I../../lib -rmagic_xml

users = XML.load('users.xml').children(:user_tuple).sort_by{|i| i[:@name]}
items = XML.load('items.xml')
bids  = XML.load('bids.xml')

XML.result! {
    users.each{|u|
        user! {
            add! u.child(:name)
            bids.find_all{|b|
                b.is_a? XML and b[:@userid] == u[:@userid]
            }.map{|b| b[:@itemno]}.uniq.map{|b|
                items.find{|i| i.is_a? XML and i[:@itemno] == b}[:@description]
            }.sort.each{|dsc|
                bid_on_item! dsc
            }
        }
    }
}
