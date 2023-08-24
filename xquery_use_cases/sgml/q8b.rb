#!/usr/bin/env ruby -I../../lib -rmagic_xml

XML.result! {
    doc = XML.load('sgml.xml')
# If we don't normalize "single text node" isn't very meaningful
    doc.normalize!
    doc.descendants(:section) {|s|
        add! s if s.descendants(:title).any?{|t|
            t.descendants.any?{|d| d.is_a? String and d =~ /is SGML/}
        }
    }
}
