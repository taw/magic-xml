#!/usr/bin/env ruby

require "magic_xml"

items = XML.load('items.xml')
bids  = XML.load('bids.xml')

allbikes = items.children({:@description => /Bicycle|Tricycle/}).map{|item| item[:@itemno]}

XML.high_bid! {
    add! bids.find_all{|b| b.is_a? XML and allbikes.include? b[:@itemno]}.map{|b| b[:@bid].to_i}.max
}
