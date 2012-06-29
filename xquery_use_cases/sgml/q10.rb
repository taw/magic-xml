#!/usr/bin/ruby -I../../lib -rmagic_xml

doc = XML.load('sgml.xml')

XML.result! {
    xref = doc.descendants(:xref).find{|xref| xref[:xrefid] == "top4"}
    add! doc.range(nil,xref).descendants(:title)[-1]
}
