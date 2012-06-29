#!/usr/bin/ruby -I../../lib -rmagic_xml

company_data = XML.load('company-data.xml')
# Root of company-data is company already,
# so there is no point in searching for a particular company there.
partners = company_data.descendants(:partner).map{|p| p.text}
c = company_data[:@name]

XML.load('string.xml').descendants(:news_item) {|item|
    next unless item.text.include? c
    next unless partners.any?{|p| item.text.include? p}
    next if item[:@news_agent] == c
    print item
}
