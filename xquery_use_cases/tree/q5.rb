#!/usr/bin/env ruby

require "magic_xml"

XML.section_list! {
    XML.load('book.xml').descendants(:section) {|s|
        section!({
            :title => s[:@title],
            :figcount => s.children(:figure).size,
        })
    }
}
