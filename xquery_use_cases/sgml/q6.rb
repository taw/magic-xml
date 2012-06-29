#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.result! {
    XML.load('sgml.xml').descendants(:section).each{|s|
        stitle! s[:shorttitle]
    }
}
