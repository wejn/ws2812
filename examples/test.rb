#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../ext', __FILE__))
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812'
include Ws2812::Lowlevel
init(64)
at_exit do
	clear
	show
	terminate(0)
end
#rainbow(5)
setBrightness(1)
theaterChase(Color(0xff, 0xff, 0x0), 44)
