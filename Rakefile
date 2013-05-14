require 'rdoc/task'

task :default => :package

# This package format is probably not what you want for anything
desc "Build package"
task :package => :doc do
  date_string = Time.new.gmtime.strftime("%Y-%m-%d-%H-%M")
  files = FileList[*%w[
    lib/magic_xml.rb tests.rb
    doc/**/*
    simple_examples/*
    xquery_use_cases/*/*
    xquery_use_cases/README
    xquery_use_cases/*.rb
  ]].exclude{|fn| File.directory? fn}

  files = files.map{|f| "magic-xml/#{f}"}
  Dir.chdir("..") {
    sh "tar", "-z", "-c", "-f", "magic_xml-#{date_string}.tar.gz", *files
    sh "zip", "-q", "-9", "magic_xml-#{date_string}.zip", *files
  }
end

desc "Run tests with Ruby 1.8"
task :tests_1_8 do
  ruby_bin = "ruby"
  Dir.chdir("xquery_use_cases") { sh ruby_bin, "./test_driver.rb", ruby_bin }
  sh ruby_bin, "./tests.rb"
end

desc "Run tests with Ruby 1.9"
task :tests_1_9 do
  ruby_bin = "ruby1.9"
  Dir.chdir("xquery_use_cases") { sh ruby_bin, "./test_driver.rb", ruby_bin }
  sh ruby_bin, "./tests.rb"
end

desc "Run all tests with Ruby 1.8/1.9"
task :test => [:tests_1_8, :tests_1_9]

desc "Clean generated files"
task :clean do
  rm_rf "doc/"
  rm_rf "coverage/"
end

class File
  def self.update_contents(file_name)
    old_contents = File.read(file_name)
    new_contents = yield(old_contents)
    if old_contents != new_contents
      File.open(file_name, "w") {|fh| fh.print new_contents}
    end
  end
end

def rcov_strip_timestamps(file_name)
  File.update_contents(file_name) do |cnt|
    cnt.sub(%r[<p>Generated on .*? with <a href='http://eigenclass\.org/hiki\.rb\?rcov'>rcov .*?</a>\n],"").
        sub(%r[<p>Generated on .*? with <a href="http://github\.com/relevance/rcov">rcov .*?</a></p>], "")

  end
end

desc "Build documentation"
task :doc => [:clean, :rdoc] do
  File.delete("doc/created.rid")
  sh "rcov ./tests.rb"
  # rcov doesn't have any easy way of turning off timestamps, so let's simply cut them out
  Dir["coverage/*.html"].each do |file_name|
    rcov_strip_timestamps(file_name)
  end
end

rd = Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "magic/xml"
  # rdoc.options << '--inline-source'
  rdoc.rdoc_files.include(Dir["**/*.rb"].select{|x| x != "jamis.rb"})
  rdoc.template = './jamis.rb'
end 
