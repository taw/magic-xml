#!/usr/bin/ruby -I../.. -rmagic_xml

XML.load('string.xml').descendants(:news_item, :title).each{|t|
    print t if t =~ /Foobar Corporation/
}
