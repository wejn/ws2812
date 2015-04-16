#!/usr/bin/env ruby

require 'mkmf'
Dir.chdir(File.join(File.dirname(__FILE__), 'lib')) do
	system "make"
	fail "building lib failed" unless $?.exitstatus.zero?
end
unless FileTest.exists?(File.dirname(__FILE__) + '/lowlevel_wrap.c')
	Dir.chdir(File.dirname(__FILE__)) do
		system *%w[swig2.0 -Wall -ruby -prefix ws2812:: -initname lowlevel lowlevel.i]
		fail "swig failed; perhaps aptitude install swig2.0" unless $?.exitstatus.zero?
	end
end
find_library('ws2812-RPi', 'init', File.dirname(__FILE__) + '/lib')
create_makefile 'ws2812/lowlevel'

File.open('Makefile', 'at') do |mk|
	mk.puts <<EOF
clean: clean-rpilowlevel
distclean: distclean-rpilowlevel

clean-rpilowlevel:
	rm -f Makefile
	make -Clib clean

distclean-rpilowlevel:
	rm -f *_wrap.c
EOF
end
