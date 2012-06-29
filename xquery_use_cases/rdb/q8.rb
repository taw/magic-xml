#!/usr/bin/ruby -I../.. -rmagic_xml

XML.item_count! XML.load('items.xml').find_all{|item| item.is_a? XML and item[:@end_day] =~ /^1999-03/}.size
