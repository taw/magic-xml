#!/usr/bin/ruby -I../../lib -rmagic_xml

# Root of company-data is company already,
# so there is no point in searching for a particular company there.
partners = XML.load('company-data.xml').descendants(:partner).map{|p| p.text}

XML.load('string.xml').descendants(:news_item) {|item|
    next unless (item.descendants(:title) + item.descendants(:par)).any?{|t|
       t.text.include? "Foobar Corporation" and partners.any?{|p| t.text.include? p}
    }
    XML.news_item!(item.child(:title), item.child(:date))
}
