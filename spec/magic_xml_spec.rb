require "stringio"

# Migration from test/unit
def expect_equal(a,b,msg=nil)
  expect(a).to eq(b)
end

describe XML do
  # Test whether XML.new constructors work (without monadic case)
  it "constructors" do
    br = XML.new(:br)
    h3 = XML.new(:h3, "Hello")
    a  = XML.new(:a, {:href => "http://www.google.com/"}, "Google")
    ul = XML.new(:ul, XML.new(:li, "Hello"), XML.new(:li, "world"))

    expect(br.to_s).to eq("<br/>")
    expect(h3.to_s).to eq("<h3>Hello</h3>")
    expect( a.to_s).to eq("<a href='http://www.google.com/'>Google</a>")
    expect(ul.to_s).to eq("<ul><li>Hello</li><li>world</li></ul>")
  end

  # Test character escaping on output, in text and in attribute values
  it "escapes" do
    p = XML.new(:p, "< > &")
    foo = XML.new(:foo, {:bar=>"< > ' \" &"})

    expect(p.to_s).to eq("<p>&lt; &gt; &amp;</p>")
    expect(foo.to_s).to eq("<foo bar='&lt; &gt; &apos; &quot; &amp;'/>")
  end

  # Test #sort_by and #children_sort_by
  it "sort_by" do
    doc = XML.parse("<foo><bar id='5'/>a<bar id='3'/>c<bar id='4'/>b<bar id='1'/></foo>")

    doc_by_id = doc.sort_by{|c| c[:id]}
    expect_equal("<foo><bar id='1'/><bar id='3'/><bar id='4'/><bar id='5'/></foo>", doc_by_id.to_s)

    doc_all_by_id = doc.children_sort_by{|c| if c.is_a? XML then [0, c[:id]] else [1, c] end}
    expect_equal("<foo><bar id='1'/><bar id='3'/><bar id='4'/><bar id='5'/>abc</foo>", doc_all_by_id.to_s)
  end

  # Test XML#[] and XML#[]= for attribute access
  it "attr" do
    foo = XML.new(:foo, {:x => "1"})
    expect("1").to eq(foo[:x])
    foo[:x] = "2"
    foo[:y] = "3"
    expect("2").to eq(foo[:x])
    expect("3").to eq(foo[:y])
  end

  # Test XML#<< method for adding children
  it "add" do
    a = XML.new(:p, "Hello")
    a << ", "
    a << "world!"
    expect_equal("<p>Hello, world!</p>", a.to_s, "XML#<< should work")

    b = XML.new(:foo)
    b << XML.new(:bar)
    expect_equal("<foo><bar/></foo>", b.to_s, "XML#<< should work")
  end

  # Test XML#each method for iterating over children
  it "each" do
    a = XML.new(:p, "Hello", ", ", "world", XML.new(:br))
    b = ""
    a.each{|c| b += c.to_s}
    expect_equal("Hello, world<br/>", b, "XML#each should work")
  end

  # Test XML#map method
  it "map" do
    a = XML.new(:body, XML.new(:h3, "One"), "Hello", XML.new(:h3, "Two"))
    b = a.map{|c|
      if c.is_a? XML and c.name == :h3
        XML.new(:h2, c.attrs, *c.contents)
      else
        c
      end
    }
    expect_equal("<body><h3>One</h3>Hello<h3>Two</h3></body>", a.to_s, "XML#map should not modify the argument")
    expect_equal("<body><h2>One</h2>Hello<h2>Two</h2></body>", b.to_s, "XML#map should work")

    d = a.map(:h3) {|c|
      XML.new(:h2, c.attrs, *c.contents)
    }
    expect_equal("<body><h2>One</h2>Hello<h2>Two</h2></body>", d.to_s, "XML#map should accept selectors")
  end

  it "==" do
    a = XML.new(:foo)
    b = XML.new(:foo)
    c = XML.new(:bar)
    expect(a).to eq(a)
    expect(a).to eq(b)
    expect(a).to_not eq(c)

    d = XML.new(:foo, {:bar => "1"})
    e = XML.new(:foo, {:bar => "1"})
    f = XML.new(:foo, {:bar => "2"})
    expect(d).to eq(d)
    expect(d).to eq(e)
    expect(d).to_not eq(f)

    a = XML.new(:foo, "Hello, world!")
    b = XML.new(:foo, "Hello, world!")
    c = XML.new(:foo, "Hello", ", world!")
    d = XML.new(:foo, "Hello")
    e = XML.new(:foo, "Hello", "")
    expect(a).to eq(a)
    expect(a).to eq(b)
    expect(a).to eq(c)
    expect(a).to_not eq(d)
    expect(d).to eq(e) # "Empty children should not affect XML#=="

    # Highly pathological case
    a = XML.new(:foo, "ab", "cde", "", "fg", "hijk", "", "")
    b = XML.new(:foo, "", "abc", "d", "efg", "h", "ijk")
    expect(a).to eq(b) # "XML#== should work with differently split Strings too"

    # String vs XML
    a = XML.new(:foo, "Hello")
    b = XML.new(:foo) {foo!}
    c = XML.new(:foo) {bar!}
    expect(a).to_not eq(b) # "XML#== should work with children of different types"
    expect(b).to_not eq(c) # XML#== should work recursively"

    a = XML.new(:foo) {foo!; bar!}
    b = XML.new(:foo) {foo!; foo!}
    expect(a).to_not eq(b) # "XML#== should work recursively"
  end

  # Test dup-with-block method
  it "dup" do
    a = XML.new(:foo, {:a => "1"}, "Hello")
    b = a.dup{ @name = :bar }
    c = a.dup{ self[:a] = "2" }
    d = a.dup{ self << ", world!" }

    expect_equal("<foo a='1'>Hello</foo>", a.to_s, "XML#dup{} should not modify its argument")
    expect_equal("<bar a='1'>Hello</bar>", b.to_s, "XML#dup{} should work")
    expect_equal("<foo a='2'>Hello</foo>", c.to_s, "XML#dup{} should work")
    expect_equal("<foo a='1'>Hello, world!</foo>", d.to_s, "XML#dup{} should work")

    # Deep copy test
    a = XML.new(:h3, "Hello")
    b = XML.new(:foo, XML.new(:bar, a))
    c = b.dup
    a << ", world!"

    expect_equal("<foo><bar><h3>Hello, world!</h3></bar></foo>", b.to_s, "XML#dup should make a deep copy")
    expect_equal("<foo><bar><h3>Hello</h3></bar></foo>", c.to_s, "XML#dup should make a deep copy")
  end

  # Test XML#normalize! method
  it "normalize" do
    a = XML.new(:foo, "He", "", "llo")
    b = XML.new(:foo, "")
    c = XML.new(:foo, "", XML.new(:bar, "1"), "", XML.new(:bar, "2", ""), "X", XML.new(:bar, "", "3"), "")

    a.normalize!
    b.normalize!
    c.normalize!

    expect_equal(["Hello"], a.contents, "XML#normalize! should work")
    expect_equal([], b.contents, "XML#normalize! should work")
    expect_equal([XML.new(:bar, "1"), XML.new(:bar, "2"), "X", XML.new(:bar, "3")], c.contents, "XML#normalize! should work")
  end

  # Test the "monadic" interface, that is constructors
  # with instance_eval'd blocks passed to them:
  # XML.new(:foo) { bar! } # -> <foo><bar/></foo>
  it "monadic" do
    a = XML.new(:foo) { bar!; xml!(:xxx) }
    b = xml(:div) {
      ul! {
        li!(XML.a("Hello"))
      }
    }
    expect_equal("<foo><bar/><xxx/></foo>", a.to_s, "Monadic interface should work")
    expect_equal("<div><ul><li><a>Hello</a></li></ul></div>", b.to_s, "Monadic interface should work")
  end

  # Test if parsing and printing gives the right results
  # We test mostly round-trip
  it "parse" do
    a = "<foo/>"
    b = "<foo a='1'/>"
    c = "<foo>Hello</foo>"
    d = "<foo a='1'><bar b='2'>Hello</bar><bar b='3'>world</bar></foo>"
    e = "<foo>&gt; &lt; &amp;</foo>"
    f = "<foo a='b&amp;c'/>"

    expect(XML.parse(a).to_s).to eq(a)
    expect(XML.parse(b).to_s).to eq(b)
    expect(XML.parse(c).to_s).to eq(c)
    expect(XML.parse(d).to_s).to eq(d)
    expect(XML.parse(e).to_s).to eq(e)
    expect(XML.parse(f).to_s).to eq(f)
  end

  # Test parsing &-entities
  it "parse_extra_escapes" do
    a     = "<foo>&quot; &apos;</foo>"
    a_out = "<foo>\" '</foo>"

    expect_equal(a_out, XML.parse(a).to_s, "XML.parse(x).to_s should normalize entities in x")
  end

  # Test handling extra cruft
  # Some things are best ignored or normalized
  it "parse_extra_cdata" do
    a     = "<foo><![CDATA[<greeting>Hello, world!</greeting>]]></foo>"
    a_out = "<foo>&lt;greeting&gt;Hello, world!&lt;/greeting&gt;</foo>"
    expect_equal(a_out, XML.parse(a).to_s, "XML.parse(x).to_s should equal normalized x")
  end

  # Test handling (=ignoring) XML declarations
  it "parse_extra_qxml" do
    b     = "<?xml version=\"1.0\"?><greeting>Hello, world!</greeting>"
    b_out = "<greeting>Hello, world!</greeting>"
    expect_equal(b_out, XML.parse(b).to_s, "XML.parse(x).to_s should equal normalized x")
  end

  # Test handling (=ignoring) DTDs
  it "parse_extra_dtd" do
    c     = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><!DOCTYPE greeting [<!ELEMENT greeting (#PCDATA)>]><greeting>Hello, world!</greeting>"
    c_out = "<greeting>Hello, world!</greeting>"
    expect_equal(c_out, XML.parse(c).to_s, "XML.parse(x).to_s should equal normalized x")
  end

  # Test handling (=ignoring) DTDs
  it "parse_extra_comment" do
    c     = "<!-- this is a comment --><greeting>Hello,<!-- another comment --> world!</greeting>"
    c_out = "<greeting>Hello, world!</greeting>"
    expect_equal(c_out, XML.parse(c).to_s, "XML.parse(x).to_s should equal normalized x")
  end

  # Test reading from a file
  it "parse_file" do
    a = File.open("test.xml").xml_parse
    b = XML.from_file("test.xml")
    c = XML.from_url("file:test.xml")
    d = XML.from_url("string:<foo><bar></bar></foo>")
    e = XML.parse("<foo><bar></bar></foo>")
    f = "<foo><bar></bar></foo>".xml_parse
    g = XML.foo { bar! }

    expect_equal(g.to_s, a.to_s, "File#xml_parse should work")
    expect_equal(g.to_s, b.to_s, "XML.from_file should work")
    expect_equal(g.to_s, c.to_s, "XML.from_url(\"file:...\") should work")
    expect_equal(g.to_s, d.to_s, "XML.from_url(\"string:...\") should work")
    expect_equal(g.to_s, e.to_s, "XML.parse should work")
    expect_equal(g.to_s, f.to_s, "String#xml_parse should work")
  end

  # Test XML#children and Array#children
  it "chilrden" do
    a = XML.bar({:x=>"1"})
    b = XML.bar({:x=>"3"})
    c = XML.bar({:x=>"2"}, b)
    d = XML.foo(a,c)
    e = d.children(:bar)
    f = e.children(:bar)
    expect_equal([a,c], e, "XML#children(tag) should return tag-tagged children")
    expect_equal([b], f, "Array#children(tag) should return tag-tagged children of its elements")
  end

  # Test XML#descendants and Array#descendants
  it "descendants" do
    a = XML.bar({:x=>"1"})
    b = XML.bar({:x=>"3"})
    c = XML.bar({:x=>"2"}, b)
    d = XML.foo(a,c)
    e = d.descendants(:bar)
    f = e.descendants(:bar)
    expect_equal([a,c,b], e, "XML#descendants(tag) should return tag-tagged descendants")
    expect_equal([b], f, "Array#descendants(tag) should return tag-tagged descendants of its elements")
  end

  # Test XML#exec! monadic interface
  it "exec" do
    a = XML.foo
    a.exec! {
      bar! { text! "Hello" }
      text! "world"
    }
    expect_equal("<foo><bar>Hello</bar>world</foo>", a.to_s, "XML#exec! should work")
  end

  # Test XML#child
  it "child" do
    a = XML.parse("<foo></foo>")
    b = XML.parse("<foo><bar a='1'/></foo>")
    c = XML.parse("<foo><bar a='1'/><bar a='2'/></foo>")

    expect_equal(nil, a.child(:bar), "XML#child should return nil if there are no matching children")
    expect_equal("<bar a='1'/>", b.child(:bar).to_s, "XML#child should work")
    expect_equal("<bar a='1'/>", c.child(:bar).to_s, "XML#child should return first child if there are many")
    expect_equal("<bar a='2'/>", c.child({:a => '2'}).to_s, "XML#child should support patterns")
  end

  # Test XML#descendant
  it "descendant" do
    a = XML.parse("<foo></foo>")
    b = XML.parse("<foo><bar a='1'/></foo>")
    c = XML.parse("<foo><bar a='1'/><bar a='2'/></foo>")
    d = XML.parse("<foo><bar a='1'><bar a='2'/></bar><bar a='3'/></foo>")
    e = XML.parse("<foo><foo><bar a='1'/></foo><bar a='2'/></foo>")

    expect_equal(nil, a.descendant(:bar), "XML#descendant should return nil if there are no matching descendants")
    expect_equal("<bar a='1'/>", b.descendant(:bar).to_s, "XML#descendant should work")
    expect_equal("<bar a='1'/>", c.descendant(:bar).to_s, "XML#descendant should return first descendant if there are many")
    expect_equal("<bar a='1'><bar a='2'/></bar>", d.descendant(:bar).to_s, "XML#descendant should return first descendant if there are many")
    expect_equal("<bar a='1'/>", e.descendant(:bar).to_s, "XML#descendant should return first descendant if there are many")
    expect_equal("<bar a='2'/>", c.descendant({:a => '2'}).to_s, "XML#descendant should support patterns")
    expect_equal("<bar a='2'/>", d.descendant({:a => '2'}).to_s, "XML#descendant should support patterns")
    expect_equal("<bar a='2'/>", e.descendant({:a => '2'}).to_s, "XML#descendant should support patterns")
  end

  # Test XML#text
  it "text" do
    a = XML.parse("<foo>Hello</foo>")
    b = XML.parse("<foo></foo>")
    c = XML.parse("<foo><bar>Hello</bar></foo>")
    d = XML.parse("<foo>He<bar>llo</bar></foo>")

    expect_equal("Hello", a.text, "XML#text should work")
    expect_equal("", b.text, "XML#text should work")
    expect_equal("Hello", c.text, "XML#text should work")
    expect_equal("Hello", d.text, "XML#text should work")
  end

  # Test XML#renormalize and XML#renormalize_sequence
  it "renormalize" do
    a = "<foo></foo>"
    b = "<foo></foo><bar></bar>"

    expect_equal("<foo/>", XML.renormalize(a), "XML#renormalize should work")
    expect_equal("<foo/>", XML.renormalize_sequence(a), "XML#renormalize_sequence should work")
    expect_equal("<foo/><bar/>", XML.renormalize_sequence(b), "XML#renormalize_sequence should work")
  end

  # Test XML#range
  it "range" do
    a = XML.parse "<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>"
    b = a.children(:bar)

    # Non-recursive case
    ar_n_n = a.range(nil, nil)
    ar_0_n = a.range(b[0], nil)
    ar_1_n = a.range(b[1], nil)
    ar_4_n = a.range(b[4], nil)
    ar_n_4 = a.range(nil, b[4])
    ar_n_3 = a.range(nil, b[3])
    ar_n_0 = a.range(nil, b[0])

    expect_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_n_n.to_s, "XML#range should work")
    expect_equal("<foo><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_0_n.to_s, "XML#range should work")
    expect_equal("<foo><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_1_n.to_s, "XML#range should work")
    expect_equal("<foo/>", ar_4_n.to_s, "XML#range should work")
    expect_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/></foo>", ar_n_4.to_s, "XML#range should work")
    expect_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/></foo>", ar_n_3.to_s, "XML#range should work")
    expect_equal("<foo/>", ar_n_0.to_s, "XML#range should work")

    a = XML.parse "<a>
           <b i='0'><c i='0'/><c i='1'/><c i='2'/></b>
           <b i='1'><c i='3'/><c i='4'/><c i='5'/></b>
           <b i='2'><c i='6'/><c i='7'/><c i='8'/></b>
           </a>"
    c = a.descendants(:c)

    c.each_with_index{|ci,i|
      c.each_with_index{|cj,j|
        next unless i < j
        ar = a.range(ci,cj)
        cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
        expect_equal(((i+1)...j).to_a, cs_present, "XML#range(c#{i}, c#{j}) should contain cs between #{i} and #{j}, exclusive, instead got: #{ar}")
      }
      ar = a.range(ci,nil)
      cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
      expect_equal(((i+1)..8).to_a, cs_present, "XML#range(c#{i}, nil) should contain cs from #{i+1} to 8, instead got: #{ar}")

      ar = a.range(nil,ci)
      cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
      expect_equal((0...i).to_a, cs_present, "XML#range(nil, c#{i}) should contain cs from 0 to #{i-1}, instead got: #{ar}")
    }
  end

  # Test XML#subsequence
  it "subsequence" do
    a = XML.parse "<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>"
    b = a.children(:bar)

    # Non-recursive case
    ar_n_n = a.subsequence(nil, nil)
    ar_0_n = a.subsequence(b[0], nil)
    ar_1_n = a.subsequence(b[1], nil)
    ar_4_n = a.subsequence(b[4], nil)
    ar_n_4 = a.subsequence(nil, b[4])
    ar_n_3 = a.subsequence(nil, b[3])
    ar_n_0 = a.subsequence(nil, b[0])

    expect_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_n_n.join, "XML#subsequence should work")
    expect_equal("<bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/>", ar_0_n.join, "XML#subsequence should work")
    expect_equal("<bar i='2'/><bar i='3'/><bar i='4'/>", ar_1_n.join, "XML#subsequence should work")
    expect_equal("", ar_4_n.join, "XML#subsequence should work")
    expect_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/></foo>", ar_n_4.join, "XML#subsequence should work")
    expect_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/></foo>", ar_n_3.join, "XML#subsequence should work")
    expect_equal("<foo/>", ar_n_0.join, "XML#subsequence should work")

    a = XML.parse "<a>
           <b j='0'><c i='0'/><c i='1'/><c i='2'/></b>
           <b j='1'><c i='3'/><c i='4'/><c i='5'/></b>
           <b j='2'><c i='6'/><c i='7'/><c i='8'/></b>
           </a>"
    c = a.descendants(:c)

    # (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}
    # instead of ar.descendants(:c) because
    # we might have returned [<c i='?'/>] as a result,
    # and then it's not a descendant of the result then.
    # This is ugly, and it should be fixed somewhere in magic/xml
    c.each_with_index{|ci,i|
      c.each_with_index{|cj,j|
        next unless i < j
        ar = a.subsequence(ci,cj)
        cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
        expect_equal(((i+1)...j).to_a, cs_present, "XML#subsequence(c#{i}, c#{j}) should contain cs between #{i} and #{j}, exclusive, instead got: #{ar.join}")
      }
      ar = a.subsequence(ci,nil)
      cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
      expect_equal(((i+1)..8).to_a, cs_present, "XML#subsequence(c#{i}, nil) should contain cs from #{i+1} to 8, instead got: #{ar.join}")

      ar = a.subsequence(nil,ci)
      cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
      expect_equal((0...i).to_a, cs_present, "XML#subsequence(nil, c#{i}) should contain cs from 0 to #{i-1}, instead got: #{ar.join}")
    }
  end

  # Test xml! at top level
  it "xml_bang" do
    real_stdout = $stdout
    $stdout = StringIO.new
    xml!(:foo)
    expect_equal("<foo/>", $stdout.string, "xml! should work")

    $stdout = StringIO.new
    XML.bar!
    expect_equal("<bar/>", $stdout.string, "XML#foo! should work")
    $stdout = real_stdout
  end

  # Methods XML#foo! are all catched,
  # but how about other methods ?
  it "real_method_missing" do
    foo = XML.new(:foo)
    exception_raised = false
    begin
      foo.bar()
    rescue NoMethodError
      exception_raised = true
    end
    # FIXME: There are other assertions than expect_equal ;-)
    expect_equal(true, exception_raised, "XML#bar should raise NoMethodError")
  end

  # Test XML#parse_as_twigs interface
  it "parse_as_twigs" do
    stream = "<foo><p><ul><li>1</li><li>2</li><li>3</li></ul></p><p><br/></p><p/><p><bar/></p></foo>"
    i = 0
    results = []
    XML.parse_as_twigs(stream) {|n|
      n.complete! if i == 1 or i == 3
      results << n
      i += 1
    }
    expect_equal("<foo/>", results[0].to_s, "XML.parse_as_twigs should work")
    expect_equal("<p><ul><li>1</li><li>2</li><li>3</li></ul></p>", results[1].to_s, "XML.parse_as_twigs should work")
    expect_equal("<p/>", results[2].to_s, "XML.parse_as_twigs should work")
    expect_equal("<br/>", results[3].to_s, "XML.parse_as_twigs should work")
    expect_equal("<p/>", results[4].to_s, "XML.parse_as_twigs should work")
    expect_equal("<p/>", results[5].to_s, "XML.parse_as_twigs should work")
    expect_equal("<bar/>", results[6].to_s, "XML.parse_as_twigs should work")
    expect_equal(7, results.size, "XML.parse_as_twigs should work")
  end

  # Test XML#inspect
  it "inpsect" do
    a = xml(:a, xml(:b, xml(:c)))
    d = xml(:d)

    expect_equal("<a>...</a>", a.inspect, "XML#inspect should work")
    expect_equal("<a>...</a>", a.inspect(0), "XML#inspect(levels) should work")
    expect_equal("<a><b>...</b></a>", a.inspect(1), "XML#inspect(levels) should work")
    expect_equal("<a><b><c/></b></a>", a.inspect(2), "XML#inspect(levels) should work")
    expect_equal("<a><b><c/></b></a>", a.inspect(3), "XML#inspect(levels) should work")
    expect_equal("<d/>", d.inspect, "XML#inspect should work")
    expect_equal("<d/>", d.inspect(0), "XML#inspect should work")
    expect_equal("<d/>", d.inspect(1), "XML#inspect should work")
  end

  # Test XML#[:@foo] pseudoattributes
  it "pseudoattributes_read" do
    # Ignore the second <x>...</x>
    a = XML.parse("<foo x='10'><x>20</x><y>30</y><x>40</x></foo>")

    # XML#[] real attributes
    expect_equal("10", a[:x])
    expect(a[:y]).to be_nil
    expect(a[:z]).to be_nil
    # XML#[] pseudoattributes
    expect_equal("20", a[:@x])
    expect_equal("30", a[:@y])
    expect(a[:@z]).to be_nil
  end

  # Test XML#[:@foo] pseudoattributes
  it "pseudoattributes_write" do
    # Ignore the second <x>...</x>
    a = XML.parse("<foo x='10'><x>20</x><y>30</y><x>40</x></foo>")

    a[:x] = 100
    a[:y] = 200
    a[:z] = 300
    a[:@x] = 1000
    a[:@y] = 2000
    a[:@z] = 3000

    expect_equal("<foo x='100' y='200' z='300'><x>1000</x><y>2000</y><x>40</x><z>3000</z></foo>", a.to_s, "XML#[]= pseudoattributes should work")
  end

  # Test entity unescaping
  it "entities" do
    a = XML.parse("<foo>&#xA5;&#xFC;&#x2020;</foo>")
    b = XML.parse("<foo>&#165;&#252;&#8224;</foo>")
    c = XML.parse("<foo>&yen;&uuml;&dagger;</foo>")
    d = ""

    expect_equal(b.text, a.text, "Entity unescaping on XML#Parse should work")
    expect_equal(c.text, a.text, "Entity unescaping on XML#Parse should work")

    expect_equal(b.to_s, a.to_s, "Entity escaping on XML#to_s should work")
    expect_equal(c.to_s, a.to_s, "Entity escaping on XML#to_s should work")

    # The escapes assume \XXX are byte escapes and the encoding is UTF-8
    expect_equal("\302\245\303\274\342\200\240", a.text, "Entity unescaping on XML#Parse should work")
    expect_equal("<foo>\302\245\303\274\342\200\240</foo>", a.to_s, "Entity escaping on XML#to_s should work")
  end

  # Test patterns support
  it "patterns" do
    a = XML.parse "<foo><bar color='blue'>Hello</bar>, <bar color='red'>world</bar><excl>!</excl></foo>"
    a.normalize!

    blue    = []
    nocolor = []
    bar     = []
    #hello   = []

    a.descendants {|d|
      case d
      when :bar
        bar << d
      end

      case d
      when {:color => 'blue'}
        blue << d
      end

      case d
      when {:color => nil}
        nocolor << d
      end

      #case d
      #when /Hello/
      #    hello << d
      #end
    }

    expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")], bar, "Pattern matching should work")
    expect_equal([XML.parse("<bar color='blue'>Hello</bar>")], blue, "Pattern matching should work")
    expect_equal([XML.parse("<excl>!</excl>")], nocolor, "Pattern matching should work")
    # Commented out, as it requires overloading Regexp#=~ and therefore Binding.of_caller
    #expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"], hello, "Pattern matching should work")
  end

  # Test pattern support in #descendants (works the same way in #children)
  it "patterns_2" do
    a = XML.parse "<foo><bar color='blue'>Hello</bar>, <bar color='red'>world</bar><excl color='blue'>!</excl></foo>"
    a.normalize!

    bar      = a.descendants(:bar)
    blue     = a.descendants({:color=>'blue'})
    blue_bar = a.descendants(All[:bar, {:color=>'blue'}])
    #hello    = a.descendants(/Hello/)
    xml      = a.descendants(XML)
    string   = a.descendants(String)

    expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")], bar, "Pattern matching should work")
    expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<excl color='blue'>!</excl>")], blue, "Pattern matching should work")
    expect_equal([XML.parse("<bar color='blue'>Hello</bar>")], blue_bar, "Pattern matching should work")
    # Commented out, as it requires overloading Regexp#=~ and therefore Binding.of_caller
    #expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"], hello, "Pattern matching should work")
    expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>"), XML.parse("<excl color='blue'>!</excl>")], xml, "Pattern matching should work")
    expect_equal(['Hello', ', ', 'world', '!'], string, "Pattern matching should work")
  end

  # Test patterns =~ support
  it "patterns_3" do
    a = XML.parse "<foo><bar color='blue'>Hello</bar>, <bar color='red'>world</bar><excl>!</excl></foo>"
    a.normalize!

    blue    = []
    nocolor = []
    bar     = []
    hello   = []

    a.descendants{|d|
      if d.is_a?(XML) and d =~ :bar
        bar << d
      end

      if d =~ {:color => 'blue'}
        blue << d
      end

      if d =~ {:color => nil}
        nocolor << d
      end

      if d =~ /Hello/
        hello << d
      end
    }

    expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")], bar, "Pattern matching should work")
    expect_equal([XML.parse("<bar color='blue'>Hello</bar>")], blue, "Pattern matching should work")
    expect_equal([XML.parse("<excl>!</excl>")], nocolor, "Pattern matching should work")
    expect_equal([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"], hello, "Pattern matching should work")
  end

  it "patterns_any_all" do
    a = XML.parse "<foo>
    <bar color='blue' size='big'>1</bar>
    <bar color='blue'>2</bar>
    <bar color='blue' size='normal'>3</bar>
    <bar color='red' size='big'>4</bar>
    <bar color='red'>5</bar>
    <bar color='red' size='normal'>6</bar>
    </foo>"

    p = All[{:color => 'red'}, Any[{:size => nil}, {:size => 'normal'}]]
    # Select childern which color red and size either normal or not specified
    b = a.children(p)
    c = a.find_all{|x| x =~ p }
    d = a.find_all{|x| p === x }

    expect_equal("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>", b.join, "Pattern matching with any/all should work")
    expect_equal("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>", c.join, "Pattern matching with any/all should work")
    expect_equal("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>", d.join, "Pattern matching with any/all should work")
  end

  # Test parse option :ignore_pretty_printing
  it "remove_pretty_printing" do
    a = "<foo><bar>100</bar><bar>200</bar></foo>"
    b = "<foo>
       <bar>
        100
       </bar>
       <bar>
        200
       </bar>
      </foo>"
    c = XML.parse(a)
    d = XML.parse(b)
    e = XML.parse(b).tap(&:remove_pretty_printing!)

    expect(c.to_s).to_not eq(d.to_s) # XML#parse should not ignore pretty printing by default
    expect(c.to_s).to eq(e.to_s) # XML#remove_pretty_printing! should work

    f = XML.parse("<foo> <bar>Hello    world</bar> </foo>")
    f.remove_pretty_printing!
    g = XML.parse("<foo><bar>Hello world</bar></foo>")
    expect_equal(f.to_s, g.to_s, "XML#remove_pretty_printing! should work")
  end

  # Test remove_pretty_printing! with exception list
  it "remove_pretty_printing_conditional" do
    a = "<foo>
       <pre>
        <a> 100 </a>
       </pre>
       <xyzzy>
        <a> 200 </a>
       </xyzzy>
      </foo>"
    b = "<foo><pre>
        <a> 100 </a>
       </pre><xyzzy><a>200</a></xyzzy></foo>"

    ax = XML.parse(a)
    bx = XML.parse(b)

    ax.remove_pretty_printing!([:pre])

    expect_equal(bx.to_s, ax.to_s, "XML#remove_pretty_printing!(exceptions) should work")
  end

  # Test extra arguments to XML#parse - :comments and :pi
  it "parsing_extras" do
    a = "<foo><?xml-stylesheet href='http://www.blogger.com/styles/atom.css' type='text/css'?></foo>"
    b = "<foo><!-- This is a comment --></foo>"

    ax = XML.parse(a)
    bx = XML.parse(b)

    expect_equal("<foo/>", ax.to_s, "XML#parse should drop PI by default")
    expect_equal("<foo/>", bx.to_s, "XML#parse should drop comments by default")

    ay = XML.parse(a, :comments => true, :pi => true)
    by = XML.parse(b, :comments => true, :pi => true)

    expect_equal(a, ay.to_s, "XML#parse(str, :pi=>true) should include PI")
    expect_equal(b, by.to_s, "XML#parse(str, :comments=>true) should include comments")
  end

  # Test extra arguments to XML#parse - :remove_pretty_printing.
  # FIXME: How about a shorter (but still mnemonic) name for that ?
  it "parsing_nopp" do
    a = "<foo><bar>100</bar><bar>200</bar></foo>"
    b = "<foo>
       <bar>
        100
       </bar>
       <bar>
        200
       </bar>
      </foo>"
    c = XML.parse(a)
    d = XML.parse(b)
    e = XML.parse(b, :remove_pretty_printing => true)

    expect(c.to_s).to_not eq(d.to_s) # XML#parse should not ignore pretty printing by default
    expect(c.to_s).to eq(e.to_s) # XML#parse(str, :remove_pretty_printing=>true) should work
  end

  # Test XML.parse(str, :extra_entities => ...)
  it "parsing_entities" do
    a = "<foo>&cat; &amp; &dog;</foo>"
    b = XML.parse(a, :extra_entities => lambda{|e|
      case e
      when "cat"
        "neko"
      when "dog"
        "inu"
      end
    })
    c = XML.parse(a, :extra_entities => {"cat" => "neko", "dog" => "inu"})

    expect_equal("neko & inu", b.text, "XML#parse(str, :extra_entities=>Proc) should work")
    expect_equal("neko & inu", c.text, "XML#parse(str, :extra_entities=>Hash) should work")

    d = XML.parse(a, :extra_entities => {"cat" => "neko", "dog" => "inu"})

    # Central European characters escapes
    e = "<foo>&zdot;&oacute;&lstrok;w</foo>"
    f = XML.parse(e, :extra_entities => {"zdot" => 380, "oacute" => 243, "lstrok" => 322})

    # Assumes \number does bytes, UTF8
    expect_equal("\305\274\303\263\305\202w", f.text, "XML#parse(str, :extra_entities=>...) should work with integer codepoints")
  end

  # Test XML.load
  it "#load" do
    a = XML.load("test.xml")
    b = XML.load(File.open("test.xml"))
    c = XML.load("string:<foo><bar></bar></foo>")
    d = XML.load("file:test.xml")

    expect(a.to_s).to eq("<foo><bar/></foo>")
    expect(b.to_s).to eq("<foo><bar/></foo>")
    expect(c.to_s).to eq("<foo><bar/></foo>")
    expect(d.to_s).to eq("<foo><bar/></foo>")
  end

  # Test multielement selectors
  it "multielement_selectors" do
    a = XML.parse("<foo><bar color='blue'><x/></bar><bar color='red'><x><y i='1'/></x><y i='2'/></bar></foo>")
    expect_equal("<x/><x><y i='1'/></x>", a.children(:bar, :x).join, "Multielement selectors should work")
    expect_equal("<y i='2'/>", a.children(:bar, :y).join, "Multielement selectors should work")
    expect_equal("<y i='1'/><y i='2'/>", a.children(:bar, :*, :y).join, "Multielement selectors should work")
    expect_equal("<y i='1'/>", a.descendants(:x, :y).join, "Multielement selectors should work")
    expect_equal("<y i='1'/><y i='2'/>", a.children(:bar, :*, :y).join, "Multielement selectors should work")
  end

  # Test deep_map
  it "deep_map" do
    a = XML.parse("<foo><bar>x</bar> <foo><bar>y</bar></foo></foo>")
    b = a.deep_map(:bar) {|c| XML.new(c.text.to_sym) }
    expect(b.to_s).to eq("<foo><x/> <foo><y/></foo></foo>")

    c = XML.parse("<foo><bar>x</bar> <bar><bar>y</bar></bar></foo>")
    d = c.deep_map(:bar) {|c| XML.new(:xyz, c.attrs, *c.children) }
    expect(d.to_s).to eq("<foo><xyz>x</xyz> <xyz><bar>y</bar></xyz></foo>")
  end

  # Test XML.load
  it "add_pretty_printing!" do
    a = XML.parse("<foo><bar>x</bar>Boo!<bar><y><z>f</z></y></bar><xyzzy /><bar>Mutiline\nText\n:-)</bar></foo>")
    a.add_pretty_printing!
    expected = "<foo>
  <bar>
    x
  </bar>
  Boo!
  <bar>
    <y>
      <z>
        f
      </z>
    </y>
  </bar>
  <xyzzy/>
  <bar>
    Mutiline
    Text
    :-)
  </bar>
</foo>"
    expect(a.to_s).to eq(expected)
  end
end
