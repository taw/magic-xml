describe "xquery comparison" do
  Dir.glob("#{__dir__}/../xquery_use_cases/*/q*.rb").sort.each do |ruby_solution|
    ruby_solution =~ /\A(.*)\/q(.*)\.rb\z/
    dir, name = $1, $2
    it "#{name}" do
      expected = File.read("#{dir}/q#{name}.out")
      got = Dir.chdir(dir) { `./q#{name}.rb` }

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

      expect( got ).to eq( expected )
    end
  end
end
