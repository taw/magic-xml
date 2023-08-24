#!/usr/bin/env ruby

require "magic_xml"

doc = XML.load('sgml.xml')

XML.result! {
    doc.descendants(:xref) {|xref|
        add! doc.descendants(:topic).find_all{|t| t[:topicid] == xref[:xrefid]}
    }
}
