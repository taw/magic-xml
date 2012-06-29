#!/usr/bin/ruby -I../../lib -rmagic_xml

bids = XML.load('bids.xml').children(:bid_tuple)

XML.result! {
    bids_of_item = Hash.new([])
    sum_bids_of_item = Hash.new(0.0)
    bids.each{|b|
        i = b[:@itemno]
        bids_of_item[i] += [b]
        sum_bids_of_item[i] += b[:@bid].to_i
    }
    bids_of_item.find_all{|i,b| b.size >= 3}.map{|i,b| [sum_bids_of_item[i] / b.size, i, b]}.sort.reverse.each{|a,i,b|
        popular_item! {
            itemno! i
# This is ugly hack to get 1.0 print as "1" not as "1.0"
            a = a.to_i if a.to_i == a
            avgbid! a
        }
    
    }
}
