#!/usr/bin/env ruby

require 'mkmf'
#$libs = append_library($libs, "lib/libws2812-RPi.a")
Dir.chdir(File.join(File.dirname(__FILE__), 'lib')) do
	system "make"
	fail "building lib failed" unless $?.exitstatus.zero?
end
system *%w[swig2.0 -Wall -ruby ws2812.i]
fail "swig failed; perhaps aptitude install swig2.0" unless $?.exitstatus.zero?
find_library('ws2812-RPi', 'init', 'lib')
dummy_makefile 'fofoa'
create_makefile 'ws2812'

File.open('Makefile', 'at') do |mk|
	mk.puts <<EOF
clean: clean-generated

clean-generated:
	rm -f Makefile ws2812_wrap.c
	make -Clib clean
EOF
end
