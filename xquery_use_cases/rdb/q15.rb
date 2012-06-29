#!/usr/bin/ruby -I../.. -rmagic_xml

users = XML.load('users.xml')
bids  = XML.load('bids.xml')

XML.result! {
    users.each(XML){|u|
        next unless bids.find_all{|b| b.is_a? XML and b[:@userid] == u[:@userid] and b[:@bid].to_i >= 100 }.size > 1
        big_spender! u[:@name]
    }
}
