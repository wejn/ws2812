#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812'

# Init
hat = Ws2812::UnicornHAT.new

# first corner set to red
red = Ws2812::Color.new(0xff, 0, 0)
hat[0, 0] = red
hat[0, 1] = red
hat[1, 0] = red

# second to green
green = Ws2812::Color.new(0, 0xff, 0)
hat[6, 7] = green
hat[7, 7] = green
hat[7, 6] = green

# middle part
hat[3, 3] = red
hat[4, 4] = green


# show it
hat.show

sleep 0.5

# rotate around till ^C
puts "Spinning... ^C to terminate"
begin
	loop do
		# rotate around
		for rot in [90, 180, 270, 0]
			hat.rotation = rot
			hat.show

			sleep 0.5
		end
	end
rescue Interrupt
end

# Clear the display at the end
hat.clear
hat.show
