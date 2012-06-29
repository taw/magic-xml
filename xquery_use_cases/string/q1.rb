#!/usr/bin/ruby -I../../lib -rmagic_xml

XML.load('string.xml').descendants(:news_item, :title).each{|t|
    print t if t =~ /Foobar Corporation/
}
