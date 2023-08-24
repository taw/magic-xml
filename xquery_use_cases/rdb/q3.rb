#!/usr/bin/env ruby

require "magic_xml"

items = XML.load('items.xml')
users = XML.load('users.xml')

XML.result! {
    users.each(XML){|u|
        next unless u[:@rating] > "C"
        items.each(XML){|i|
            next unless i[:@reserve_price].to_i > 1000
            warning!(u.child(:name), u.child(:rating), i.child(:description), i.child(:reserve_price))
        }
    }
}
