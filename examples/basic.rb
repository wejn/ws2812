#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812'

# Init
n = 64 # num leds
ws = Ws2812::Basic.new(n, 18) # +n+ leds at pin 18, using defaults
ws.open

# first pixel set to red
ws[0] = Ws2812::Color.new(0xff, 0, 0)

# all other set to green
ws[(1...n)] = Ws2812::Color.new(0, 0xff, 0)

# second pixel set to blue, via individual components
ws.set(1, 0, 0, 0xff)

# show it
ws.show
sleep 1

# increase brightness and show it
ws.brightness = 100
ws.show
sleep 1

# decrease brightness and show it
ws.brightness = 50
ws.show
sleep 1

# Dump state of all leds
require 'pp'
pp ws[(0...n)].reduce([[]]) { |m, x| m << [] if m[-1].size >= 8; m[-1] << x ; m}

# Show progress from all-red to all-green
ws.brightness = 5
ws[(0...n)] = Ws2812::Color.new(0xff, 0, 0)
ws.show
(0...n).each do |i|
	ws[i] = Ws2812::Color.new(0, 0xff, 0)
	ws.show
	sleep 0.1
end
