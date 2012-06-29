#!/usr/bin/ruby -I../.. -rmagic_xml

XML.load('report1.xml').descendants(:section) {|s|
    print s.descendants(:instrument)[0,2] if s[:"@section.title"] == "Procedure"
}
