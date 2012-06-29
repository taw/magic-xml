#!/usr/bin/ruby -I.. -rmagic_xml

page_title = "Hello, world"

print XML.html {
  head! {
    title! { text! page_title }
  }
  body! {
    h3! { text! page_title }
  }
}
