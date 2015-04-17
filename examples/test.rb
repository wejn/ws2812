#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812'

module Ws2812
	class Color
		def initialize(r, g, b)
			@r, @g, @b = r, g, b
		end
		attr :r, :g, :b

		def to_i
			((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff)
		end

		def self.from_i(i)
			Color.new((i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff)
		end
	end

	class NeoPixel
		include Ws2812::Lowlevel

		def initialize(num, pin, freq=800_000, dma=5, invert=false, brightness=255, channel=0)

			@leds = Ws2811_t.new

			@channel = ws2811_channel_get(@leds, channel)
			@channel.count = num
			@channel.gpionum = pin
			@channel.invert = invert ? 1 : 0
			@channel.brightness = brightness

			@leds.freq = freq
			@leds.dmanum = dma

			at_exit { self.close }

			@open = false
		end

		def open
			return nil if @open
			resp = ws2811_init(@leds)
			unless resp.zero?
				raise "init failed with code: " + resp
			end
			@open = true
			self
		end

		def close
			@open = false
			if @leds
				ws2811_fini(@leds)
				@channel = nil # will GC the memory
				@leds = nil
				# Note: ws2811_fini will free mem used by led_data internally
			end
			self
		end


		def show
			resp = ws2811_render(@leds)
			unless resp.zero?
				raise "show failed with code: " + resp
			end
		end

		def []=(n, color)
			if n.respond_to?(:to_a)
				n.to_a.each { |i| ws2811_led_set(@channel, i, color.to_i) }
			else
				ws2811_led_set(@channel, n, color.to_i)
			end
		end

		def set(n, r, g, b)
			self[n] = Color.new(r, g, b)
		end

		def brightness=(val)
			@channel.brightness = val
		end

		def brightness
			@channel.brightness
		end

		def count
			@channel.count
		end

		def [](n)
			if n.respond_to?(:to_a)
				n.to_a.map { |i| Color.from_i(ws2811_led_get(@channel, i)) }
			else
				Color.from_i(ws2811_led_get(@channel, n))
			end
		end
	end
end

if __FILE__ == $0
	ws = Ws2812::NeoPixel.new(64, 18, 800_000, 5, false, 50, 0)
	ws.open
	ws[0] = Ws2812::Color.new(0xff, 0, 0)
	ws[(1..63)] = Ws2812::Color.new(0, 0xff, 0)
	ws.set(1, 0, 0, 0xff)
	ws.show
	sleep 1
	ws.brightness = 100
	ws.show
	sleep 1
	ws.brightness = 50
	ws.show
	p ws[(0..63)]
end
