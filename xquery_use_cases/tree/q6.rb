#!/usr/bin/ruby -I../.. -rmagic_xml

def section_summary(s)
    XML.section(s.attrs) {
        add! s.child(:title)
        figcount! s.children(:figure).size
        add! s.children(:section).map{|c| section_summary(c)}
    }
end

XML.toc! {
    XML.load('book.xml').children(:section) {|s|
        add! section_summary(s)
    }
}
