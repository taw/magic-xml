#!/usr/bin/env ruby

require "magic_xml"

XML.load('report1.xml').descendants(:section) {|s|
    print s.descendants(:incision)[1].child(:instrument) if s[:"@section.title"] == "Procedure"
}
