#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.critical_sequence! {
   p = XML.load('report1.xml').descendants(:section).find {|p| p[:"@section.title"] == "Procedure"}
   i1,i2, = *p.descendants(:incision)
# Naive add! proc.subsequence(i1,i2) would do the right thing
# Do the wrong and complex thing for compatibility with XQuery solution
   add! p.subsequence(i1,i2).map{|p| [p] + [p].descendants}
}
