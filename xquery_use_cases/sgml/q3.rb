#!/usr/bin/ruby -I../.. -rmagic_xml

XML.result! {
    XML.load('sgml.xml').descendants(:chapter) {|c|
        next unless c.children(:intro).empty?
        add! c.children(:section, :intro, :para)
    }
}
