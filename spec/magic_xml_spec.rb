require "stringio"

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
    expect(doc_by_id.to_s).to eq("<foo><bar id='1'/><bar id='3'/><bar id='4'/><bar id='5'/></foo>")

    doc_all_by_id = doc.children_sort_by{|c| if c.is_a? XML then [0, c[:id]] else [1, c] end}
    expect(doc_all_by_id.to_s).to eq("<foo><bar id='1'/><bar id='3'/><bar id='4'/><bar id='5'/>abc</foo>")
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
    expect(a.to_s).to eq("<p>Hello, world!</p>")

    b = XML.new(:foo)
    b << XML.new(:bar)
    expect(b.to_s).to eq("<foo><bar/></foo>")
  end

  # Test XML#each method for iterating over children
  it "each" do
    a = XML.new(:p, "Hello", ", ", "world", XML.new(:br))
    b = ""
    a.each{|c| b += c.to_s}
    expect(b).to eq("Hello, world<br/>")
  end

  # Test XML#map method
  it "map" do
    a = XML.new(:body, XML.new(:h3, "One"), "Hello", XML.new(:h3, "Two"))
    b = a.map do |c|
      if c.is_a? XML and c.name == :h3
        XML.new(:h2, c.attrs, *c.contents)
      else
        c
      end
    end
    expect(a.to_s).to eq("<body><h3>One</h3>Hello<h3>Two</h3></body>") # XML#map should not modify the argument
    expect(b.to_s).to eq("<body><h2>One</h2>Hello<h2>Two</h2></body>") # XML#map should work

    d = a.map(:h3) do |e|
      XML.new(:h2, e.attrs, *e.contents)
    end
    expect(d.to_s).to eq("<body><h2>One</h2>Hello<h2>Two</h2></body>") # XML#map should accept selectors
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

    expect(a.to_s).to eq("<foo a='1'>Hello</foo>")
    expect(b.to_s).to eq("<bar a='1'>Hello</bar>")
    expect(c.to_s).to eq("<foo a='2'>Hello</foo>")
    expect(d.to_s).to eq("<foo a='1'>Hello, world!</foo>")

    # Deep copy test
    a = XML.new(:h3, "Hello")
    b = XML.new(:foo, XML.new(:bar, a))
    c = b.dup
    a << ", world!"

    expect(b.to_s).to eq("<foo><bar><h3>Hello, world!</h3></bar></foo>")
    expect(c.to_s).to eq("<foo><bar><h3>Hello</h3></bar></foo>")
  end

  # Test XML#normalize! method
  it "normalize" do
    a = XML.new(:foo, "He", "", "llo")
    b = XML.new(:foo, "")
    c = XML.new(:foo, "", XML.new(:bar, "1"), "", XML.new(:bar, "2", ""), "X", XML.new(:bar, "", "3"), "")

    a.normalize!
    b.normalize!
    c.normalize!

    expect(a.contents).to eq(["Hello"])
    expect(b.contents).to eq([])
    expect(c.contents).to eq([XML.new(:bar, "1"), XML.new(:bar, "2"), "X", XML.new(:bar, "3")])
  end

  # Test the "monadic" interface, that is constructors
  # with instance_eval'd blocks passed to them:
  # XML.new(:foo) { bar! } # -> <foo><bar/></foo>
  it "monadic" do
    a = XML.new(:foo) do
      bar!
      xml!(:xxx)
    end
    b = xml(:div) do
      ul! do
        li!(XML.a("Hello"))
      end
    end
    expect(a.to_s).to eq("<foo><bar/><xxx/></foo>")
    expect(b.to_s).to eq("<div><ul><li><a>Hello</a></li></ul></div>")
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
    expect(XML.parse(a).to_s).to eq(a_out)
  end

  # Test handling extra cruft
  # Some things are best ignored or normalized
  it "parse_extra_cdata" do
    a     = "<foo><![CDATA[<greeting>Hello, world!</greeting>]]></foo>"
    a_out = "<foo>&lt;greeting&gt;Hello, world!&lt;/greeting&gt;</foo>"
    expect(XML.parse(a).to_s).to eq(a_out)
  end

  # Test handling (=ignoring) XML declarations
  it "parse_extra_qxml" do
    b     = "<?xml version=\"1.0\"?><greeting>Hello, world!</greeting>"
    b_out = "<greeting>Hello, world!</greeting>"
    expect(XML.parse(b).to_s).to eq(b_out)
  end

  # Test handling (=ignoring) DTDs
  it "parse_extra_dtd" do
    c     = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><!DOCTYPE greeting [<!ELEMENT greeting (#PCDATA)>]><greeting>Hello, world!</greeting>"
    c_out = "<greeting>Hello, world!</greeting>"
    expect(XML.parse(c).to_s).to eq(c_out)
  end

  # Test handling (=ignoring) DTDs
  it "parse_extra_comment" do
    c     = "<!-- this is a comment --><greeting>Hello,<!-- another comment --> world!</greeting>"
    c_out = "<greeting>Hello, world!</greeting>"
    expect(XML.parse(c).to_s).to eq(c_out)
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

    expect(a.to_s).to eq(g.to_s) # File#xml_parse should work
    expect(b.to_s).to eq(g.to_s) # XML.from_file should work
    expect(c.to_s).to eq(g.to_s) # XML.from_url(\"file:...\") should work
    expect(d.to_s).to eq(g.to_s) # XML.from_url(\"string:...\") should work
    expect(e.to_s).to eq(g.to_s) # XML.parse should work
    expect(f.to_s).to eq(g.to_s) # String#xml_parse should work
  end

  # Test XML#children and Array#children
  it "chilrden" do
    a = XML.bar({:x=>"1"})
    b = XML.bar({:x=>"3"})
    c = XML.bar({:x=>"2"}, b)
    d = XML.foo(a,c)
    e = d.children(:bar)
    f = e.children(:bar)
    expect(e).to eq([a,c]) # XML#children(tag) should return tag-tagged children
    expect(f).to eq([b])   # Array#children(tag) should return tag-tagged children of its elements
  end

  # Test XML#descendants and Array#descendants
  it "descendants" do
    a = XML.bar({:x=>"1"})
    b = XML.bar({:x=>"3"})
    c = XML.bar({:x=>"2"}, b)
    d = XML.foo(a,c)
    e = d.descendants(:bar)
    f = e.descendants(:bar)
    expect(e).to eq([a,c,b]) # XML#descendants(tag) should return tag-tagged descendants
    expect(f).to eq([b]) # Array#descendants(tag) should return tag-tagged descendants of its elements
  end

  # Test XML#exec! monadic interface
  it "exec" do
    a = XML.foo
    a.exec! do
      bar! do
        text! "Hello"
      end
      text! "world"
    end
    expect(a.to_s).to eq("<foo><bar>Hello</bar>world</foo>")
  end

  # Test XML#child
  it "child" do
    a = XML.parse("<foo></foo>")
    b = XML.parse("<foo><bar a='1'/></foo>")
    c = XML.parse("<foo><bar a='1'/><bar a='2'/></foo>")

    expect(a.child(:bar)).to eq(nil) # XML#child should return nil if there are no matching children
    expect(b.child(:bar).to_s).to eq("<bar a='1'/>") # XML#child should work
    expect(c.child(:bar).to_s).to eq("<bar a='1'/>") # XML#child should return first child if there are many
    expect(c.child({:a => '2'}).to_s).to eq("<bar a='2'/>") # XML#child should support patterns
  end

  # Test XML#descendant
  it "descendant" do
    a = XML.parse("<foo></foo>")
    b = XML.parse("<foo><bar a='1'/></foo>")
    c = XML.parse("<foo><bar a='1'/><bar a='2'/></foo>")
    d = XML.parse("<foo><bar a='1'><bar a='2'/></bar><bar a='3'/></foo>")
    e = XML.parse("<foo><foo><bar a='1'/></foo><bar a='2'/></foo>")

    expect(a.descendant(:bar)).to eq(nil) # XML#descendant should return nil if there are no matching descendants
    expect(b.descendant(:bar).to_s).to eq("<bar a='1'/>") # XML#descendant should work
    expect(c.descendant(:bar).to_s).to eq("<bar a='1'/>") # XML#descendant should return first descendant if there are many
    expect(d.descendant(:bar).to_s).to eq("<bar a='1'><bar a='2'/></bar>") # XML#descendant should return first descendant if there are many
    expect(e.descendant(:bar).to_s).to eq("<bar a='1'/>") # XML#descendant should return first descendant if there are many
    expect(c.descendant({:a => '2'}).to_s).to eq("<bar a='2'/>") # XML#descendant should support patterns
    expect(d.descendant({:a => '2'}).to_s).to eq("<bar a='2'/>") # XML#descendant should support patterns
    expect(e.descendant({:a => '2'}).to_s).to eq("<bar a='2'/>") # XML#descendant should support patterns
  end

  # Test XML#text
  it "text" do
    a = XML.parse("<foo>Hello</foo>")
    b = XML.parse("<foo></foo>")
    c = XML.parse("<foo><bar>Hello</bar></foo>")
    d = XML.parse("<foo>He<bar>llo</bar></foo>")

    expect(a.text).to eq("Hello")
    expect(b.text).to eq("")
    expect(c.text).to eq("Hello")
    expect(d.text).to eq("Hello")
  end

  # Test XML#renormalize and XML#renormalize_sequence
  it "renormalize" do
    a = "<foo></foo>"
    b = "<foo></foo><bar></bar>"

    expect(XML.renormalize(a)).to eq("<foo/>")
    expect(XML.renormalize_sequence(a)).to eq("<foo/>")
    expect(XML.renormalize_sequence(b)).to eq("<foo/><bar/>")
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

    expect(ar_n_n.to_s).to eq("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>")
    expect(ar_0_n.to_s).to eq("<foo><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>")
    expect(ar_1_n.to_s).to eq("<foo><bar i='2'/><bar i='3'/><bar i='4'/></foo>")
    expect(ar_4_n.to_s).to eq("<foo/>")
    expect(ar_n_4.to_s).to eq("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/></foo>")
    expect(ar_n_3.to_s).to eq("<foo><bar i='0'/><bar i='1'/><bar i='2'/></foo>")
    expect(ar_n_0.to_s).to eq("<foo/>")

    a = XML.parse "<a>
           <b i='0'><c i='0'/><c i='1'/><c i='2'/></b>
           <b i='1'><c i='3'/><c i='4'/><c i='5'/></b>
           <b i='2'><c i='6'/><c i='7'/><c i='8'/></b>
           </a>"
    c = a.descendants(:c)

    c.each_with_index do |ci,i|
      c.each_with_index do |cj,j|
        next unless i < j
        ar = a.range(ci,cj)
        cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
        expect(((i+1)...j).to_a).to eq(cs_present) # XML#range(c#{i}, c#{j}) should contain cs between #{i} and #{j}, exclusive, instead got: #{ar}"
      end
      ar = a.range(ci,nil)
      cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
      expect(((i+1)..8).to_a).to eq(cs_present) # XML#range(c#{i}, nil) should contain cs from #{i+1} to 8, instead got: #{ar}"

      ar = a.range(nil,ci)
      cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
      expect((0...i).to_a).to eq(cs_present) # XML#range(nil, c#{i}) should contain cs from 0 to #{i-1}, instead got: #{ar}"
    end
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

    expect(ar_n_n.join).to eq("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>")
    expect(ar_0_n.join).to eq("<bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/>")
    expect(ar_1_n.join).to eq("<bar i='2'/><bar i='3'/><bar i='4'/>")
    expect(ar_4_n.join).to eq("")
    expect(ar_n_4.join).to eq("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/></foo>")
    expect(ar_n_3.join).to eq("<foo><bar i='0'/><bar i='1'/><bar i='2'/></foo>")
    expect(ar_n_0.join).to eq("<foo/>")

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
    c.each_with_index do |ci,i|
      c.each_with_index do |cj,j|
        next unless i < j
        ar = a.subsequence(ci,cj)
        cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
        # XML#subsequence(c#{i}, c#{j}) should contain cs between #{i} and #{j}, exclusive, instead got: #{ar.join}
        expect(cs_present).to eq(((i+1)...j).to_a)
      end
      ar = a.subsequence(ci,nil)
      cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
        # XML#subsequence(c#{i}, nil) should contain cs from #{i+1} to 8, instead got: #{ar.join}
      expect(cs_present).to eq(((i+1)..8).to_a)

      ar = a.subsequence(nil,ci)
      cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
      # XML#subsequence(nil, c#{i}) should contain cs from 0 to #{i-1}, instead got: #{ar.join}
      expect(cs_present).to eq((0...i).to_a)
    end
  end

  # Test xml! at top level
  it "xml_bang" do
    real_stdout = $stdout
    $stdout = StringIO.new
    xml!(:foo)
    expect($stdout.string).to eq("<foo/>")

    $stdout = StringIO.new
    XML.bar!
    expect($stdout.string).to eq("<bar/>")
    $stdout = real_stdout
  end

  # Methods XML#foo! are all catched,
  # but how about other methods ?
  it "real_method_missing" do
    foo = XML.new(:foo)
    expect{ foo.bar }.to raise_error(NoMethodError)
  end

  # Test XML#parse_as_twigs interface
  it "parse_as_twigs" do
    stream = "<foo><p><ul><li>1</li><li>2</li><li>3</li></ul></p><p><br/></p><p/><p><bar/></p></foo>"
    i = 0
    results = []
    XML.parse_as_twigs(stream) do |n|
      n.complete! if i == 1 or i == 3
      results << n
      i += 1
    end
    expect(results[0].to_s).to eq("<foo/>")
    expect(results[1].to_s).to eq("<p><ul><li>1</li><li>2</li><li>3</li></ul></p>")
    expect(results[2].to_s).to eq("<p/>")
    expect(results[3].to_s).to eq("<br/>")
    expect(results[4].to_s).to eq("<p/>")
    expect(results[5].to_s).to eq("<p/>")
    expect(results[6].to_s).to eq("<bar/>")
    expect(results.size).to eq(7)
  end

  # Test XML#inspect
  it "inpsect" do
    a = xml(:a, xml(:b, xml(:c)))
    d = xml(:d)

    expect(a.inspect   ).to eq("<a>...</a>")
    expect(a.inspect(0)).to eq("<a>...</a>")
    expect(a.inspect(1)).to eq("<a><b>...</b></a>")
    expect(a.inspect(2)).to eq("<a><b><c/></b></a>")
    expect(a.inspect(3)).to eq("<a><b><c/></b></a>")
    expect(d.inspect   ).to eq("<d/>")
    expect(d.inspect(0)).to eq("<d/>")
    expect(d.inspect(1)).to eq("<d/>")
  end

  # Test XML#[:@foo] pseudoattributes
  it "pseudoattributes_read" do
    # Ignore the second <x>...</x>
    a = XML.parse("<foo x='10'><x>20</x><y>30</y><x>40</x></foo>")

    # XML#[] real attributes
    expect(a[:x]).to eq("10")
    expect(a[:y]).to be_nil
    expect(a[:z]).to be_nil
    # XML#[] pseudoattributes
    expect(a[:@x]).to eq("20")
    expect(a[:@y]).to eq("30")
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

    expect(a.to_s).to eq("<foo x='100' y='200' z='300'><x>1000</x><y>2000</y><x>40</x><z>3000</z></foo>")
  end

  # Test entity unescaping
  it "entities" do
    a = XML.parse("<foo>&#xA5;&#xFC;&#x2020;</foo>")
    b = XML.parse("<foo>&#165;&#252;&#8224;</foo>")
    c = XML.parse("<foo>&yen;&uuml;&dagger;</foo>")

    # The escapes assume \XXX are byte escapes and the encoding is UTF-8

    expect(a.text).to eq("\302\245\303\274\342\200\240")
    expect(b.text).to eq(a.text)
    expect(c.text).to eq(a.text)

    expect(a.to_s).to eq("<foo>\302\245\303\274\342\200\240</foo>")
    expect(b.to_s).to eq(a.to_s)
    expect(c.to_s).to eq(a.to_s)
  end

  # Test patterns support
  it "patterns" do
    a = XML.parse "<foo><bar color='blue'>Hello</bar>, <bar color='red'>world</bar><excl>!</excl></foo>"
    a.normalize!

    blue    = []
    nocolor = []
    bar     = []
    #hello   = []

    a.descendants do |d|
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
    end

    expect(bar).to eq([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")])
    expect(blue).to eq([XML.parse("<bar color='blue'>Hello</bar>")])
    expect(nocolor).to eq([XML.parse("<excl>!</excl>")])
    # Commented out, as it requires overloading Regexp#=~ and therefore Binding.of_caller
    #expect(hello).to eq([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"])
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

    expect(bar).to eq([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")])
    expect(blue).to eq([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<excl color='blue'>!</excl>")])
    expect(blue_bar).to eq([XML.parse("<bar color='blue'>Hello</bar>")])
    # Commented out, as it requires overloading Regexp#=~ and therefore Binding.of_caller
    #expec(hello).to eql([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"])
    expect(xml).to eq([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>"), XML.parse("<excl color='blue'>!</excl>")])
    expect(string).to eq(['Hello', ', ', 'world', '!'])
  end

  # Test patterns =~ support
  it "patterns_3" do
    a = XML.parse "<foo><bar color='blue'>Hello</bar>, <bar color='red'>world</bar><excl>!</excl></foo>"
    a.normalize!

    blue    = []
    nocolor = []
    bar     = []
    hello   = []

    a.descendants do |d|
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
    end

    expect(bar).to eq([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")])
    expect(blue).to eq([XML.parse("<bar color='blue'>Hello</bar>")])
    expect(nocolor).to eq([XML.parse("<excl>!</excl>")])
    expect(hello).to eq([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"])
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

    expect(b.join).to eq("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>")
    expect(c.join).to eq("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>")
    expect(d.join).to eq("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>")
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
    expect(f.to_s).to eq(g.to_s)
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

    expect(ax.to_s).to eq(bx.to_s)
  end

  # Test extra arguments to XML#parse - :comments and :pi
  it "parsing_extras" do
    a = "<foo><?xml-stylesheet href='http://www.blogger.com/styles/atom.css' type='text/css'?></foo>"
    b = "<foo><!-- This is a comment --></foo>"

    ax = XML.parse(a)
    bx = XML.parse(b)

    expect(ax.to_s).to eq("<foo/>") # XML#parse should drop PI by default
    expect(bx.to_s).to eq("<foo/>") # XML#parse should drop comments by default

    ay = XML.parse(a, comments: true, pi: true)
    by = XML.parse(b, comments: true, pi: true)

    expect(ay.to_s).to eq(a) # XML#parse(str, :pi=>true) should include PI
    expect(by.to_s).to eq(b) # XML#parse(str, :comments=>true) should include comments
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

  # Test XML.parse(str, extra_entities: ...)
  it "parsing_entities" do
    a = "<foo>&cat; &amp; &dog;</foo>"
    b = XML.parse(a, extra_entities: lambda{|e|
      case e
      when "cat"
        "neko"
      when "dog"
        "inu"
      end
    })
    c = XML.parse(a, extra_entities: {"cat" => "neko", "dog" => "inu"})

    expect(b.text).to eq("neko & inu")  # XML#parse(str, :extra_entities=>Proc) should work
    expect(c.text).to eq("neko & inu")  # XML#parse(str, :extra_entities=>Hash) should work

    # Central European characters escapes
    e = "<foo>&zdot;&oacute;&lstrok;w</foo>"
    f = XML.parse(e, extra_entities: {"zdot" => 380, "oacute" => 243, "lstrok" => 322})

    # Assumes \number does bytes, UTF8
    expect(f.text).to eq("\305\274\303\263\305\202w") # XML#parse(str, :extra_entities=>...) should work with integer codepoints
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
    expect(a.children(:bar, :x).join).to eq("<x/><x><y i='1'/></x>")
    expect(a.children(:bar, :y).join).to eq("<y i='2'/>")
    expect(a.children(:bar, :*, :y).join).to eq("<y i='1'/><y i='2'/>")
    expect(a.descendants(:x, :y).join).to eq("<y i='1'/>")
    expect(a.children(:bar, :*, :y).join).to eq("<y i='1'/><y i='2'/>")
  end

  # Test deep_map
  it "deep_map" do
    a = XML.parse("<foo><bar>x</bar> <foo><bar>y</bar></foo></foo>")
    b = a.deep_map(:bar) {|c| XML.new(c.text.to_sym) }
    expect(b.to_s).to eq("<foo><x/> <foo><y/></foo></foo>")

    c = XML.parse("<foo><bar>x</bar> <bar><bar>y</bar></bar></foo>")
    d = c.deep_map(:bar) {|e| XML.new(:xyz, e.attrs, *e.children) }
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
