#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.load('report1.xml').descendants(:section) {|s|
    print s.descendants(:instrument)[0,2].join if s[:"@section.title"] == "Procedure"
}
