#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.load('report1.xml').descendants(:section) {|p|
    next unless p[:"@section.title"] == "Procedure"
    i1 = p.descendants(:incision)[0]
    print p if p.range(nil,i1).descendants(:anesthesia).size == 0
}
