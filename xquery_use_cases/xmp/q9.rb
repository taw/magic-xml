#!/usr/bin/ruby -I../.. -rmagic_xml
XML.results! {
    XML.load('books.xml').descendants {|d|
        if d.is_a? XML and (d.name == :chapter or d.name == :section)
            t = d.child(:title)
            add! t  if t =~ /XML/
        end
    }
}
