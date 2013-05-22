#!/usr/bin/env ruby

require 'rubygems';
require 'json';

raise "Usage: ./convert {basepath}" unless ARGV.size >= 1;

$base = ARGV[0];

files = File.open("#{$base}/filelist.xml") do |f|
  f.readlines.map do |l|
    case l
      when /<o:File HRef="(slide[0-9]+.htm)"\/>/ then "#{$base}/#{$1}";
      else nil;
    end
  end
end.compact;

out_files = files.map do |fname|
  out_fname = fname.sub(/\.htm/, "_converted.htm");
  File.open(fname) do |inf|
    File.open(out_fname, "w+") do |outf|
      outf.puts(
        inf.readlines.
          map {|l| l.chomp }.
          join("").
          gsub(/<script>.*<\/script>/, "")
      );
    end
  end
  out_fname;
end

File.open("#{$base}/manifest.json", "w+") do |f|
  f.puts(JSON.generate({
    "slides" => out_files.map do |outf|
      { "rawURL" => true,
        "url" => outf
      };
    end
  }));
end