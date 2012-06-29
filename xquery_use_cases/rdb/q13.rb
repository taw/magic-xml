#!/usr/bin/ruby -I../../lib -rmagic_xml

users = XML.load('users.xml')
bids  = XML.load('bids.xml')

XML.result! {
    bids.descendants(:userid).map{|uid| uid.text}.uniq.sort.each{|uid|
        users.each({:@userid => uid}){|u|
            user_bids = bids.find_all{|b| b.is_a? XML and b[:@userid] == uid}
            bidder! {
                add! u.child(:userid)
                add! u.child(:name)
                bidcount! user_bids.size
                sum = 0.0
                user_bids.each{|b|
                    sum += b[:@bid].to_i
                }
                a = sum / user_bids.size
# This is ugly hack to get 1.0 print as "1" not as "1.0"
                a = a.to_i if a.to_i == a
                avgbid! a
            }
        }
    }
}
