#!/usr/bin/ruby -I../.. -rmagic_xml

def local_toc(node)
    node.children(:section).map{|c|
        XML.section(c.attrs, c.child(:title), local_toc(c))
    }
end

XML.toc! {
    add! local_toc(XML.load('book.xml'))
}
