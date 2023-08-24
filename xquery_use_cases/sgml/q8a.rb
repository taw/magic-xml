#!/usr/bin/env ruby -I../../lib -rmagic_xml

XML.result! {
    XML.load('sgml.xml').descendants(:section) {|s|
        add! s if s.descendants(:title).any?{|t| t =~ /is SGML/}
    }
}
