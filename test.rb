#!/usr/bin/env ruby
$:.unshift('.')
require 'ws2812'
include Ws2812
init(64)
at_exit do
	clear
	show
	terminate(0)
end
rainbow(5)
