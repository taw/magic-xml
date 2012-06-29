#!/usr/bin/env ruby -Ilib
require 'test/unit'
require 'magic_xml'

# For tests
require 'stringio'

class XML_Tests < Test::Unit::TestCase
    # Test whether XML.new constructors work (without monadic case)
    def test_constructors
        br = XML.new(:br)
        h3 = XML.new(:h3, "Hello")
        a  = XML.new(:a, {:href => "http://www.google.com/"}, "Google")
        ul = XML.new(:ul, XML.new(:li, "Hello"), XML.new(:li, "world"))

        assert_equal("<br/>", br.to_s, "Constructors should work")
        assert_equal("<h3>Hello</h3>", h3.to_s, "Constructors should work")
        assert_equal("<a href='http://www.google.com/'>Google</a>", a.to_s, "Constructors should work")
        assert_equal("<ul><li>Hello</li><li>world</li></ul>", ul.to_s, "Constructors should work")
    end

    # Test character escaping on output, in text and in attribute values
    def test_escapes
        p = XML.new(:p, "< > &")
        foo = XML.new(:foo, {:bar=>"< > ' \" &"})

        assert_equal("<p>&lt; &gt; &amp;</p>", p.to_s, "Character escaping should work")
        assert_equal("<foo bar='&lt; &gt; &apos; &quot; &amp;'/>", foo.to_s, "Character escaping in attributes should work")
    end

    # Test #sort_by and #children_sort_by
    def test_sort_by
        doc = XML.parse("<foo><bar id='5'/>a<bar id='3'/>c<bar id='4'/>b<bar id='1'/></foo>")
        
        doc_by_id = doc.sort_by{|c| c[:id]}
        assert_equal("<foo><bar id='1'/><bar id='3'/><bar id='4'/><bar id='5'/></foo>", doc_by_id.to_s)

        doc_all_by_id = doc.children_sort_by{|c| if c.is_a? XML then [0, c[:id]] else [1, c] end}
        assert_equal("<foo><bar id='1'/><bar id='3'/><bar id='4'/><bar id='5'/>abc</foo>", doc_all_by_id.to_s)
    end

    # Test XML#[] and XML#[]= for attribute access
    def test_attr
        foo = XML.new(:foo, {:x => "1"})
        assert_equal("1", foo[:x], "Attribute reading should work")
        foo[:x] = "2"
        foo[:y] = "3"
        assert_equal("2", foo[:x], "Attribute writing should work")
        assert_equal("3", foo[:y], "Attribute writing should work")
    end
   
    # Test XML#<< method for adding children
    def test_add
        a = XML.new(:p, "Hello")
        a << ", "
        a << "world!"
        assert_equal("<p>Hello, world!</p>", a.to_s, "XML#<< should work")

        b = XML.new(:foo)
        b << XML.new(:bar)
        assert_equal("<foo><bar/></foo>", b.to_s, "XML#<< should work")
    end
   
    # Test XML#each method for iterating over children
    def test_each
        a = XML.new(:p, "Hello", ", ", "world", XML.new(:br))
        b = ""
        a.each{|c| b += c.to_s}
        assert_equal("Hello, world<br/>", b, "XML#each should work")
    end

    # Test XML#map method
    def test_map
        a = XML.new(:body, XML.new(:h3, "One"), "Hello", XML.new(:h3, "Two"))
        b = a.map{|c|
            if c.is_a? XML and c.name == :h3
                XML.new(:h2, c.attrs, *c.contents)
            else
                c
            end
        }
        assert_equal("<body><h3>One</h3>Hello<h3>Two</h3></body>", a.to_s, "XML#map should not modify the argument")
        assert_equal("<body><h2>One</h2>Hello<h2>Two</h2></body>", b.to_s, "XML#map should work")
        
        d = a.map(:h3) {|c|
            XML.new(:h2, c.attrs, *c.contents)
        }
        assert_equal("<body><h2>One</h2>Hello<h2>Two</h2></body>", d.to_s, "XML#map should accept selectors")
    end
 
    # Test XML#==  
    def test_eqeq
        a = XML.new(:foo)
        b = XML.new(:foo)
        c = XML.new(:bar)
        assert(a==a, "XML#== should work")
        assert(a==b, "XML#== should work")
        assert(a!=c, "XML#== should work")
       
        d = XML.new(:foo, {:bar => "1"})
        e = XML.new(:foo, {:bar => "1"})
        f = XML.new(:foo, {:bar => "2"})
        assert(d==d, "XML#== should work")
        assert(d==e, "XML#== should work")
        assert(d!=f, "XML#== should work")
       
        a = XML.new(:foo, "Hello, world!")
        b = XML.new(:foo, "Hello, world!")
        c = XML.new(:foo, "Hello", ", world!")
        d = XML.new(:foo, "Hello")
        e = XML.new(:foo, "Hello", "")
        assert(a==a, "XML#== should work")
        assert(a==b, "XML#== should work")
        assert(a==c, "XML#== should work")
        assert(a!=d, "XML#== should work")
        assert(d==e, "Empty children should not affect XML#==")
       
        # Highly pathological case
        a = XML.new(:foo, "ab", "cde", "", "fg", "hijk", "", "")
        b = XML.new(:foo, "", "abc", "d", "efg", "h", "ijk")
        assert(a==b, "XML#== should work with differently split Strings too")
        
        # String vs XML
        a = XML.new(:foo, "Hello")
        b = XML.new(:foo) {foo!}
        c = XML.new(:foo) {bar!}
        assert(a!=b, "XML#== should work with children of different types")
        assert(b!=c, "XML#== should work recursively")

        a = XML.new(:foo) {foo!; bar!}
        b = XML.new(:foo) {foo!; foo!}
        assert(a!=b, "XML#== should work recursively")
    end
   
    # Test dup-with-block method
    def test_dup
        a = XML.new(:foo, {:a => "1"}, "Hello")
        b = a.dup{ @name = :bar }
        c = a.dup{ self[:a] = "2" }
        d = a.dup{ self << ", world!" }
       
        assert_equal("<foo a='1'>Hello</foo>", a.to_s, "XML#dup{} should not modify its argument")
        assert_equal("<bar a='1'>Hello</bar>", b.to_s, "XML#dup{} should work")
        assert_equal("<foo a='2'>Hello</foo>", c.to_s, "XML#dup{} should work")
        assert_equal("<foo a='1'>Hello, world!</foo>", d.to_s, "XML#dup{} should work")
       
        # Deep copy test
        a = XML.new(:h3, "Hello")
        b = XML.new(:foo, XML.new(:bar, a))
        c = b.dup
        a << ", world!"
       
        assert_equal("<foo><bar><h3>Hello, world!</h3></bar></foo>", b.to_s, "XML#dup should make a deep copy")
        assert_equal("<foo><bar><h3>Hello</h3></bar></foo>", c.to_s, "XML#dup should make a deep copy")
    end
   
    # Test XML#normalize! method
    def test_normalize
        a = XML.new(:foo, "He", "", "llo")
        b = XML.new(:foo, "")
        c = XML.new(:foo, "", XML.new(:bar, "1"), "", XML.new(:bar, "2", ""), "X", XML.new(:bar, "", "3"), "")

        a.normalize!
        b.normalize!
        c.normalize!

        assert_equal(["Hello"], a.contents, "XML#normalize! should work")
        assert_equal([], b.contents, "XML#normalize! should work")
        assert_equal([XML.new(:bar, "1"), XML.new(:bar, "2"), "X", XML.new(:bar, "3")], c.contents, "XML#normalize! should work")
    end

    # Test the "monadic" interface, that is constructors
    # with instance_eval'd blocks passed to them:
    # XML.new(:foo) { bar! } # -> <foo><bar/></foo>
    def test_monadic
        a = XML.new(:foo) { bar!; xml!(:xxx) }
        b = xml(:div) {
            ul! {
                li!(XML.a("Hello"))
            }
        }
        assert_equal("<foo><bar/><xxx/></foo>", a.to_s, "Monadic interface should work")
        assert_equal("<div><ul><li><a>Hello</a></li></ul></div>", b.to_s, "Monadic interface should work")
    end
    
    # Test if parsing and printing gives the right results
    # We test mostly round-trip
    def test_parse
        a = "<foo/>"
        b = "<foo a='1'/>"
        c = "<foo>Hello</foo>"
        d = "<foo a='1'><bar b='2'>Hello</bar><bar b='3'>world</bar></foo>"
        e = "<foo>&gt; &lt; &amp;</foo>"
        f = "<foo a='b&amp;c'/>"
        
        assert_equal(a, XML.parse(a).to_s, "XML.parse(x).to_s should equal x for normalized x")
        assert_equal(b, XML.parse(b).to_s, "XML.parse(x).to_s should equal x for normalized x")
        assert_equal(c, XML.parse(c).to_s, "XML.parse(x).to_s should equal x for normalized x")
        assert_equal(d, XML.parse(d).to_s, "XML.parse(x).to_s should equal x for normalized x")
        assert_equal(e, XML.parse(e).to_s, "XML.parse(x).to_s should equal x for normalized x")
        assert_equal(f, XML.parse(f).to_s, "XML.parse(x).to_s should equal x for normalized x")
    end

    # Test parsing &-entities
    def test_parse_extra_escapes
        a     = "<foo>&quot; &apos;</foo>"
        a_out = "<foo>\" '</foo>"

        assert_equal(a_out, XML.parse(a).to_s, "XML.parse(x).to_s should normalize entities in x")
    end

    # Test handling extra cruft
    # Some things are best ignored or normalized
    def test_parse_extra_cdata
        a     = "<foo><![CDATA[<greeting>Hello, world!</greeting>]]></foo>"
        a_out = "<foo>&lt;greeting&gt;Hello, world!&lt;/greeting&gt;</foo>"
        assert_equal(a_out, XML.parse(a).to_s, "XML.parse(x).to_s should equal normalized x")
    end

    # Test handling (=ignoring) XML declarations
    def test_parse_extra_qxml
        b     = "<?xml version=\"1.0\"?><greeting>Hello, world!</greeting>"
        b_out = "<greeting>Hello, world!</greeting>"
        assert_equal(b_out, XML.parse(b).to_s, "XML.parse(x).to_s should equal normalized x")
    end

    # Test handling (=ignoring) DTDs
    def test_parse_extra_dtd
        c     = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><!DOCTYPE greeting [<!ELEMENT greeting (#PCDATA)>]><greeting>Hello, world!</greeting>"
        c_out = "<greeting>Hello, world!</greeting>"
        assert_equal(c_out, XML.parse(c).to_s, "XML.parse(x).to_s should equal normalized x")
    end

    # Test handling (=ignoring) DTDs
    def test_parse_extra_comment
        c     = "<!-- this is a comment --><greeting>Hello,<!-- another comment --> world!</greeting>"
        c_out = "<greeting>Hello, world!</greeting>"
        assert_equal(c_out, XML.parse(c).to_s, "XML.parse(x).to_s should equal normalized x")
    end

    # Test reading from a file
    def test_parse_file
        a = File.open("test.xml").xml_parse
        b = XML.from_file("test.xml")
        c = XML.from_url("file:test.xml")
        d = XML.from_url("string:<foo><bar></bar></foo>")
        e = XML.parse("<foo><bar></bar></foo>")
        f = "<foo><bar></bar></foo>".xml_parse
        g = XML.foo { bar! }
        
        assert_equal(g.to_s, a.to_s, "File#xml_parse should work")
        assert_equal(g.to_s, b.to_s, "XML.from_file should work")
        assert_equal(g.to_s, c.to_s, "XML.from_url(\"file:...\") should work")
        assert_equal(g.to_s, d.to_s, "XML.from_url(\"string:...\") should work")
        assert_equal(g.to_s, e.to_s, "XML.parse should work")
        assert_equal(g.to_s, f.to_s, "String#xml_parse should work")
    end

    # Test XML#children and Array#children
    def test_chilrden
        a = XML.bar({:x=>"1"})
        b = XML.bar({:x=>"3"})
        c = XML.bar({:x=>"2"}, b)
        d = XML.foo(a,c)
        e = d.children(:bar)
        f = e.children(:bar)
        assert_equal([a,c], e, "XML#children(tag) should return tag-tagged children")
        assert_equal([b], f, "Array#children(tag) should return tag-tagged children of its elements")
    end
    
    # Test XML#descendants and Array#descendants
    def test_descendants
        a = XML.bar({:x=>"1"})
        b = XML.bar({:x=>"3"})
        c = XML.bar({:x=>"2"}, b)
        d = XML.foo(a,c)
        e = d.descendants(:bar)
        f = e.descendants(:bar)
        assert_equal([a,c,b], e, "XML#descendants(tag) should return tag-tagged descendants")
        assert_equal([b], f, "Array#descendants(tag) should return tag-tagged descendants of its elements")
    end

    # Test XML#exec! monadic interface
    def test_exec
        a = XML.foo
        a.exec! {
            bar! { text! "Hello" }
            text! "world"
        }
        assert_equal("<foo><bar>Hello</bar>world</foo>", a.to_s, "XML#exec! should work")
    end

    # Test XML#child
    def test_child
        a = XML.parse("<foo></foo>")
        b = XML.parse("<foo><bar a='1'/></foo>")
        c = XML.parse("<foo><bar a='1'/><bar a='2'/></foo>")

        assert_equal(nil, a.child(:bar), "XML#child should return nil if there are no matching children")
        assert_equal("<bar a='1'/>", b.child(:bar).to_s, "XML#child should work")
        assert_equal("<bar a='1'/>", c.child(:bar).to_s, "XML#child should return first child if there are many")
        assert_equal("<bar a='2'/>", c.child({:a => '2'}).to_s, "XML#child should support patterns")
    end

    # Test XML#descendant
    def test_descendant
        a = XML.parse("<foo></foo>")
        b = XML.parse("<foo><bar a='1'/></foo>")
        c = XML.parse("<foo><bar a='1'/><bar a='2'/></foo>")
        d = XML.parse("<foo><bar a='1'><bar a='2'/></bar><bar a='3'/></foo>")
        e = XML.parse("<foo><foo><bar a='1'/></foo><bar a='2'/></foo>")
        
        assert_equal(nil, a.descendant(:bar), "XML#descendant should return nil if there are no matching descendants")
        assert_equal("<bar a='1'/>", b.descendant(:bar).to_s, "XML#descendant should work")
        assert_equal("<bar a='1'/>", c.descendant(:bar).to_s, "XML#descendant should return first descendant if there are many")
        assert_equal("<bar a='1'><bar a='2'/></bar>", d.descendant(:bar).to_s, "XML#descendant should return first descendant if there are many")
        assert_equal("<bar a='1'/>", e.descendant(:bar).to_s, "XML#descendant should return first descendant if there are many")
        assert_equal("<bar a='2'/>", c.descendant({:a => '2'}).to_s, "XML#descendant should support patterns")
        assert_equal("<bar a='2'/>", d.descendant({:a => '2'}).to_s, "XML#descendant should support patterns")
        assert_equal("<bar a='2'/>", e.descendant({:a => '2'}).to_s, "XML#descendant should support patterns")
    end
    
    # Test XML#text
    def test_text
        a = XML.parse("<foo>Hello</foo>")
        b = XML.parse("<foo></foo>")
        c = XML.parse("<foo><bar>Hello</bar></foo>")
        d = XML.parse("<foo>He<bar>llo</bar></foo>")

        assert_equal("Hello", a.text, "XML#text should work")
        assert_equal("", b.text, "XML#text should work")
        assert_equal("Hello", c.text, "XML#text should work")
        assert_equal("Hello", d.text, "XML#text should work")
    end
    
    # Test XML#renormalize and XML#renormalize_sequence
    def test_renormalize
        a = "<foo></foo>"
        b = "<foo></foo><bar></bar>"
        
        assert_equal("<foo/>", XML.renormalize(a), "XML#renormalize should work")
        assert_equal("<foo/>", XML.renormalize_sequence(a), "XML#renormalize_sequence should work")
        assert_equal("<foo/><bar/>", XML.renormalize_sequence(b), "XML#renormalize_sequence should work")
    end
    
    # Test XML#range
    def test_range
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
        
        assert_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_n_n.to_s, "XML#range should work")
        assert_equal("<foo><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_0_n.to_s, "XML#range should work")
        assert_equal("<foo><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_1_n.to_s, "XML#range should work")
        assert_equal("<foo/>", ar_4_n.to_s, "XML#range should work")
        assert_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/></foo>", ar_n_4.to_s, "XML#range should work")
        assert_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/></foo>", ar_n_3.to_s, "XML#range should work")
        assert_equal("<foo/>", ar_n_0.to_s, "XML#range should work")
        
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
                assert_equal(((i+1)...j).to_a, cs_present, "XML#range(c#{i}, c#{j}) should contain cs between #{i} and #{j}, exclusive, instead got: #{ar}")
            }
            ar = a.range(ci,nil)
            cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
            assert_equal(((i+1)..8).to_a, cs_present, "XML#range(c#{i}, nil) should contain cs from #{i+1} to 8, instead got: #{ar}")
            
            ar = a.range(nil,ci)
            cs_present = ar.descendants(:c).map{|n|n[:i].to_i}
            assert_equal((0...i).to_a, cs_present, "XML#range(nil, c#{i}) should contain cs from 0 to #{i-1}, instead got: #{ar}")
        }
    end

    # Test XML#subsequence
    def test_subsequence
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
        
        assert_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/></foo>", ar_n_n.to_s, "XML#subsequence should work")
        assert_equal("<bar i='1'/><bar i='2'/><bar i='3'/><bar i='4'/>", ar_0_n.to_s, "XML#subsequence should work")
        assert_equal("<bar i='2'/><bar i='3'/><bar i='4'/>", ar_1_n.to_s, "XML#subsequence should work")
        assert_equal("", ar_4_n.to_s, "XML#subsequence should work")
        assert_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/><bar i='3'/></foo>", ar_n_4.to_s, "XML#subsequence should work")
        assert_equal("<foo><bar i='0'/><bar i='1'/><bar i='2'/></foo>", ar_n_3.to_s, "XML#subsequence should work")
        assert_equal("<foo/>", ar_n_0.to_s, "XML#subsequence should work")
        
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
                assert_equal(((i+1)...j).to_a, cs_present, "XML#subsequence(c#{i}, c#{j}) should contain cs between #{i} and #{j}, exclusive, instead got: #{ar}")
            }
            ar = a.subsequence(ci,nil)
            cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
            assert_equal(((i+1)..8).to_a, cs_present, "XML#subsequence(c#{i}, nil) should contain cs from #{i+1} to 8, instead got: #{ar}")
            
            ar = a.subsequence(nil,ci)
            cs_present = (ar + ar.descendants).find_all{|x| x.is_a? XML and x.name == :c}.map{|n| n[:i].to_i}
            assert_equal((0...i).to_a, cs_present, "XML#subsequence(nil, c#{i}) should contain cs from 0 to #{i-1}, instead got: #{ar}")
        }
    end
    
    # Test xml! at top level
    def test_xml_bang
        real_stdout = $stdout
        $stdout = StringIO.new
        xml!(:foo)
        assert_equal("<foo/>", $stdout.string, "xml! should work")
        
        $stdout = StringIO.new
        XML.bar!
        assert_equal("<bar/>", $stdout.string, "XML#foo! should work")
        $stdout = real_stdout
    end
    
    # Methods XML#foo! are all catched,
    # but how about other methods ?
    def test_real_method_missing
        foo = XML.new(:foo)
        exception_raised = false
        begin 
            foo.bar()
        rescue NoMethodError
            exception_raised = true
        end
        # FIXME: There are other assertions than assert_equal ;-)
        assert_equal(true, exception_raised, "XML#bar should raise NoMethodError")
    end
    
    # Test XML#parse_as_twigs interface
    def test_parse_as_twigs
        stream = "<foo><p><ul><li>1</li><li>2</li><li>3</li></ul></p><p><br/></p><p/><p><bar/></p></foo>"
        i = 0
        results = []
        XML.parse_as_twigs(stream) {|n|
            n.complete! if i == 1 or i == 3
            results << n
            i += 1
        }
        assert_equal("<foo/>", results[0].to_s, "XML.parse_as_twigs should work")
        assert_equal("<p><ul><li>1</li><li>2</li><li>3</li></ul></p>", results[1].to_s, "XML.parse_as_twigs should work")
        assert_equal("<p/>", results[2].to_s, "XML.parse_as_twigs should work")
        assert_equal("<br/>", results[3].to_s, "XML.parse_as_twigs should work")
        assert_equal("<p/>", results[4].to_s, "XML.parse_as_twigs should work")
        assert_equal("<p/>", results[5].to_s, "XML.parse_as_twigs should work")
        assert_equal("<bar/>", results[6].to_s, "XML.parse_as_twigs should work")
        assert_equal(7, results.size, "XML.parse_as_twigs should work")
    end

    # Test XML#inspect
    def test_inpsect
        a = xml(:a, xml(:b, xml(:c)))
        d = xml(:d)
        
        assert_equal("<a>...</a>", a.inspect, "XML#inspect should work")
        assert_equal("<a>...</a>", a.inspect(0), "XML#inspect(levels) should work")
        assert_equal("<a><b>...</b></a>", a.inspect(1), "XML#inspect(levels) should work")
        assert_equal("<a><b><c/></b></a>", a.inspect(2), "XML#inspect(levels) should work")
        assert_equal("<a><b><c/></b></a>", a.inspect(3), "XML#inspect(levels) should work")
        assert_equal("<d/>", d.inspect, "XML#inspect should work")
        assert_equal("<d/>", d.inspect(0), "XML#inspect should work")
        assert_equal("<d/>", d.inspect(1), "XML#inspect should work")
    end
    
    # Test XML#[:@foo] pseudoattributes
    def test_pseudoattributes_read
        # Ignore the second <x>...</x>
        a = XML.parse("<foo x='10'><x>20</x><y>30</y><x>40</x></foo>")
        
        assert_equal("10", a[:x],  "XML#[] real attributes should work")
        assert_nil(a[:y],  "XML#[] real attributes should work")
        assert_nil(a[:z],  "XML#[] real attributes should work")
        assert_equal("20", a[:@x], "XML#[] pseudoattributes should work")
        assert_equal("30", a[:@y], "XML#[] pseudoattributes should work")
        assert_nil(a[:@z], "XML#[] pseudoattributes should work")
    end

    # Test XML#[:@foo] pseudoattributes
    def test_pseudoattributes_write
        # Ignore the second <x>...</x>
        a = XML.parse("<foo x='10'><x>20</x><y>30</y><x>40</x></foo>")
        
        a[:x] = 100
        a[:y] = 200
        a[:z] = 300
        a[:@x] = 1000
        a[:@y] = 2000
        a[:@z] = 3000
        
        assert_equal("<foo x='100' y='200' z='300'><x>1000</x><y>2000</y><x>40</x><z>3000</z></foo>", a.to_s, "XML#[]= pseudoattributes should work")
    end
    
    # Test entity unescaping
    def test_entities
        a = XML.parse("<foo>&#xA5;&#xFC;&#x2020;</foo>")
        b = XML.parse("<foo>&#165;&#252;&#8224;</foo>")
        c = XML.parse("<foo>&yen;&uuml;&dagger;</foo>")
        d = ""
        
        assert_equal(b.text, a.text, "Entity unescaping on XML#Parse should work")
        assert_equal(c.text, a.text, "Entity unescaping on XML#Parse should work")

        assert_equal(b.to_s, a.to_s, "Entity escaping on XML#to_s should work")
        assert_equal(c.to_s, a.to_s, "Entity escaping on XML#to_s should work")

        # The escapes assume \XXX are byte escapes and the encoding is UTF-8
        assert_equal("\302\245\303\274\342\200\240", a.text, "Entity unescaping on XML#Parse should work")
        assert_equal("<foo>\302\245\303\274\342\200\240</foo>", a.to_s, "Entity escaping on XML#to_s should work")
    end

    # Test patterns support
    def test_patterns
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
        
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")], bar, "Pattern matching should work")
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>")], blue, "Pattern matching should work")
        assert_equal([XML.parse("<excl>!</excl>")], nocolor, "Pattern matching should work")
        # Commented out, as it requires overloading Regexp#=~ and therefore Binding.of_caller
        #assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"], hello, "Pattern matching should work")
    end

    # Test pattern support in #descendants (works the same way in #children)
    def test_patterns_2
        a = XML.parse "<foo><bar color='blue'>Hello</bar>, <bar color='red'>world</bar><excl color='blue'>!</excl></foo>"
        a.normalize!
        
        bar      = a.descendants(:bar)
        blue     = a.descendants({:color=>'blue'})
        blue_bar = a.descendants(all(:bar, {:color=>'blue'}))
        #hello    = a.descendants(/Hello/)
        xml      = a.descendants(XML)
        string   = a.descendants(String)
    
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")], bar, "Pattern matching should work")
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<excl color='blue'>!</excl>")], blue, "Pattern matching should work")
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>")], blue_bar, "Pattern matching should work")
        # Commented out, as it requires overloading Regexp#=~ and therefore Binding.of_caller
        #assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"], hello, "Pattern matching should work")
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>"), XML.parse("<excl color='blue'>!</excl>")], xml, "Pattern matching should work")
        assert_equal(['Hello', ', ', 'world', '!'], string, "Pattern matching should work")
    end

    # Test patterns =~ support
    def test_patterns_3
        a = XML.parse "<foo><bar color='blue'>Hello</bar>, <bar color='red'>world</bar><excl>!</excl></foo>"
        a.normalize!
        
        blue    = []
        nocolor = []
        bar     = []
        hello   = []
        
        a.descendants {|d|
            if d =~ :bar
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
        
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), XML.parse("<bar color='red'>world</bar>")], bar, "Pattern matching should work")
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>")], blue, "Pattern matching should work")
        assert_equal([XML.parse("<excl>!</excl>")], nocolor, "Pattern matching should work")
        assert_equal([XML.parse("<bar color='blue'>Hello</bar>"), "Hello"], hello, "Pattern matching should work")
    end

    def test_patterns_any_all
        a = XML.parse "<foo>
        <bar color='blue' size='big'>1</bar>
        <bar color='blue'>2</bar>
        <bar color='blue' size='normal'>3</bar>
        <bar color='red' size='big'>4</bar>
        <bar color='red'>5</bar>
        <bar color='red' size='normal'>6</bar>
        </foo>"
        
        p = all({:color => 'red'}, any({:size => nil}, {:size => 'normal'}))
        # Select childern which color red and size either normal or not specified
        b = a.children(p)
        c = a.find_all{|x| x =~ p }
        d = a.find_all{|x| p === x }
        
        assert_equal("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>", b.to_s, "Pattern matching with any/all should work")
        assert_equal("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>", c.to_s, "Pattern matching with any/all should work")
        assert_equal("<bar color='red'>5</bar><bar color='red' size='normal'>6</bar>", d.to_s, "Pattern matching with any/all should work")
    end

    # Test parse option :ignore_pretty_printing
    def test_remove_pretty_printing
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
         e = XML.parse(b)
         e.remove_pretty_printing!
         
         assert_not_equal(c.to_s, d.to_s, "XML#parse should not ignore pretty printing by default")
         assert_equal(c.to_s, e.to_s, "XML#remove_pretty_printing! should work")
         
         f = XML.parse("<foo> <bar>Hello    world</bar> </foo>")
         f.remove_pretty_printing!
         g = XML.parse("<foo><bar>Hello world</bar></foo>")
         assert_equal(f.to_s, g.to_s, "XML#remove_pretty_printing! should work")
    end

    # Test remove_pretty_printing! with exception list
    def test_remove_pretty_printing_conditional
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

        assert_equal(bx.to_s, ax.to_s, "XML#remove_pretty_printing!(exceptions) should work")
    end
    
    # Test extra arguments to XML#parse - :comments and :pi
    def test_parsing_extras
        a = "<foo><?xml-stylesheet href='http://www.blogger.com/styles/atom.css' type='text/css'?></foo>"
        b = "<foo><!-- This is a comment --></foo>"
        
        ax = XML.parse(a)
        bx = XML.parse(b)
        
        assert_equal("<foo/>", ax.to_s, "XML#parse should drop PI by default")
        assert_equal("<foo/>", bx.to_s, "XML#parse should drop comments by default")
        
        ay = XML.parse(a, :comments => true, :pi => true)
        by = XML.parse(b, :comments => true, :pi => true)

        assert_equal(a, ay.to_s, "XML#parse(str, :pi=>true) should include PI")
        assert_equal(b, by.to_s, "XML#parse(str, :comments=>true) should include comments")
    end
    
    # Test extra arguments to XML#parse - :remove_pretty_printing.
    # FIXME: How about a shorter (but still mnemonic) name for that ?
    def test_parsing_nopp
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

        assert_not_equal(c.to_s, d.to_s, "XML#parse should not ignore pretty printing by default")
        assert_equal(c.to_s, e.to_s, "XML#parse(str, :remove_pretty_printing=>true) should work")
    end
    
    # Test XML.parse(str, :extra_entities => ...)
    def test_parsing_entities
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
        
        assert_equal("neko & inu", b.text, "XML#parse(str, :extra_entities=>Proc) should work")
        assert_equal("neko & inu", c.text, "XML#parse(str, :extra_entities=>Hash) should work")
        
        d = XML.parse(a, :extra_entities => {"cat" => "neko", "dog" => "inu"})
        
        # Central European characters escapes
        e = "<foo>&zdot;&oacute;&lstrok;w</foo>"
        f = XML.parse(e, :extra_entities => {"zdot" => 380, "oacute" => 243, "lstrok" => 322})
        
        # Assumes \number does bytes, UTF8
        assert_equal("\305\274\303\263\305\202w", f.text, "XML#parse(str, :extra_entities=>...) should work with integer codepoints")
    end
    
    # Test XML.load
    def test_load
        a = XML.load("test.xml")
        b = XML.load(File.open("test.xml"))
        c = XML.load("string:<foo><bar></bar></foo>")
        d = XML.load("file:test.xml")
        
        assert_equal("<foo><bar/></foo>", a.to_s, "XML#load should work")
        assert_equal("<foo><bar/></foo>", b.to_s, "XML#load should work")
        assert_equal("<foo><bar/></foo>", c.to_s, "XML#load should work")
        assert_equal("<foo><bar/></foo>", d.to_s, "XML#load should work")
    end
    
    # Test multielement selectors
    def test_multielement_selectors
        a = XML.parse("<foo><bar color='blue'><x/></bar><bar color='red'><x><y i='1'/></x><y i='2'/></bar></foo>")
        assert_equal("<x/><x><y i='1'/></x>", a.children(:bar, :x).to_s, "Multielement selectors should work")
        assert_equal("<y i='2'/>", a.children(:bar, :y).to_s, "Multielement selectors should work")
        assert_equal("<y i='1'/><y i='2'/>", a.children(:bar, :*, :y).to_s, "Multielement selectors should work")
        assert_equal("<y i='1'/>", a.descendants(:x, :y).to_s, "Multielement selectors should work")
        assert_equal("<y i='1'/><y i='2'/>", a.children(:bar, :*, :y).to_s, "Multielement selectors should work")
    end
    
    # Test deep_map
    def test_deep_map
        a = XML.parse("<foo><bar>x</bar> <foo><bar>y</bar></foo></foo>")
        b = a.deep_map(:bar) {|c| XML.new(c.text.to_sym) }
        assert_equal("<foo><x/> <foo><y/></foo></foo>", b.to_s, "XML#deep_map should work")

        c = XML.parse("<foo><bar>x</bar> <bar><bar>y</bar></bar></foo>")
        d = c.deep_map(:bar) {|c| XML.new(:xyz, c.attrs, *c.children) }
        assert_equal("<foo><xyz>x</xyz> <xyz><bar>y</bar></xyz></foo>", d.to_s, "XML#deep_map should work")
    end

    # Test XML.load
    def test_pretty_printer
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
        assert_equal(expected, a.to_s, "XML#pretty_print! should work")
    end
end
