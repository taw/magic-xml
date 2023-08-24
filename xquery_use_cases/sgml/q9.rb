#!/usr/bin/env ruby -I../../lib -rmagic_xml

doc = XML.load('sgml.xml')

XML.result! {
    doc.descendants(:xref) {|xref|
        add! doc.descendants(:topic).find_all{|t| t[:topicid] == xref[:xrefid]}
    }
}
