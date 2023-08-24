#!/usr/bin/env ruby -I../../lib -rmagic_xml

XML.figlist! {
    XML.load('book.xml').descendants(:figure) {|f|
        figure!(f.attrs, f.children(:title))
    }
}
