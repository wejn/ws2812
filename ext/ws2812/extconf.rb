#!/usr/bin/env ruby

require 'mkmf'
unless FileTest.exists?(File.dirname(__FILE__) + '/lowlevel_wrap.c')
	Dir.chdir(File.dirname(__FILE__)) do
		system *%w[swig2.0 -Wall -ruby -prefix ws2812:: -initname lowlevel lowlevel.i]
		fail "swig failed; perhaps aptitude install swig2.0" unless $?.exitstatus.zero?
	end
end

create_makefile 'ws2812/lowlevel'
