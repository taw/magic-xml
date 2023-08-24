#!/usr/bin/env ruby -I../../lib -rmagic_xml

items = XML.load('items.xml').children(:item_tuple)

XML.result! {
    items.map{|item| item[:@end_day] =~ /^1999-(\d+)/; $1.to_i}.sort.uniq.each{|m|
        monthly_result! {
            month! m
            item_count!(items.find_all{|item| item[:@end_day] =~ /1999-(\d+)/; $1.to_i==m}.size)
        }
    }
}
