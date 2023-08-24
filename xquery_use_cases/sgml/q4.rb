#!/usr/bin/env ruby -I../../lib -rmagic_xml

XML.result!(
    XML.load('sgml.xml').descendants(:chapter)[1].descendants(:section)[2].descendants(:para)[1]
)
