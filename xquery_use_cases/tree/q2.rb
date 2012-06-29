#!/usr/bin/ruby -I../.. -rmagic_xml

XML.figlist! {
    XML.load('book.xml').descendants(:figure) {|f|
        figure!(f.attrs, f.children(:title))
    }
}
