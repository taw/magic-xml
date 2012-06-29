#!/usr/bin/env ruby

$percentages = []
$ruby_size_total = 0
$xquery_size_total = 0

Dir.glob("*/q*.rb").sort.each{|ruby_solution|
    ruby_solution =~ /^(.*)\/q(.*)\.rb$/
    dir, name = $1, $2
    xquery_solution = "#{dir}/q#{name}.xquery"
    
    # Remove #!-line from Ruby solutions
    # Remove #-comments from Ruby solutions
    #        (only those that take whole lines, otherwise we'd need a Ruby parser)
    # Change URL-access to document-access in XQuery solutions
    # Merge all whitespace into a single " "
    ruby_size = File.read(ruby_solution).sub(/^#!.*?\n/,"").gsub(/^#.*?\n/,"").gsub(/\s+/, " ").size
    xquery_size = File.read(xquery_solution).gsub(/http:\/\/bstore[12].example.com\//,"").gsub(/\s+/, " ").size
    perc = sprintf "%.0f%%", (100.0 * ruby_size / xquery_size) 
    print "Problem #{dir.upcase} Q#{name}: Ruby #{ruby_size} (#{perc}), XQuery: #{xquery_size}\n"
    $percentages.push(100.0 * ruby_size / xquery_size)
    $ruby_size_total += ruby_size
    $xquery_size_total += xquery_size
}

perc = sprintf "%.0f%%", (100.0 * $ruby_size_total / $xquery_size_total)
print "Total: Ruby #{$ruby_size_total} (#{perc}), XQuery: #{$xquery_size_total}\n"
printf "Median ratio: %.0f%%\n", $percentages.sort[$percentages.size/2]
