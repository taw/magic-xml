#!/usr/bin/env ruby -I../lib

require 'magic_xml'

tests = 0
oks   = 0

ruby_bin = ARGV.shift || "ruby"

Dir.glob("*/q*.rb").sort.each{|ruby_solution|
    ruby_solution =~ /^(.*)\/q(.*)\.rb$/
    dir, name = $1, $2

    expected = File.read("#{dir}/q#{name}.out")
    got = Dir.chdir(dir) { `#{ruby_bin} q#{name}.rb` }

    # Now, expected_out contains a lot of cruft, strip!
    expected.gsub!(/>\s+/, ">")
    expected.gsub!(/\s+</, "<")
    expected.gsub!(/\s+/, " ")
    # A bit more renormalization
    expected = XML.renormalize_sequence(expected)

    # Do the same to got, or SEQ Q5 won't match
    got.gsub!(/>\s+/, ">")
    got.gsub!(/\s+</, "<")
    got.gsub!(/\s+/, " ")

    if expected == got
        oks += 1
        print "Test #{dir.upcase} Q#{name}: match\n"
    else
        print "Test #{dir.upcase} Q#{name}:\n"
        print "Expected:\n#{expected}\n";
        print "Got:\n#{got}\n";
        print "They do not match\n\n"
    end
    tests += 1
}
print "Of #{tests} tests, #{oks} passed.\n"
