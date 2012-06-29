#!/usr/bin/ruby -I../lib -rmagic_xml

page_title = "Hello, world"

print XML.html(
  XML.head(
    XML.title(page_title)
  ),
  XML.body(
    XML.h3(page_title)
  )
)
