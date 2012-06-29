#!/usr/bin/ruby -I.. -rmagic_xml

page_title = "Hello, world"
content = ['a', 'b', 'c', 'd']

print XML.html {
  head! {
    title! { text! page_title }
  }
  body! {
    h3! { text! page_title }
    ul! { 
      content.each{|c| li! { text! c } }
    }
  }
}
