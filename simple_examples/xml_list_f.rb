#!/usr/bin/ruby -I.. -rmagic_xml

page_title = "Hello, world"
content = ['a', 'b', 'c', 'd']

print XML.html(
  XML.head(
    XML.title(page_title)
  ),
  XML.body(
    XML.h3(page_title),
    XML.ul(
      *content.map{|c| XML.li(c) }
    )
  )
)
