#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812'

class Digit
	n = nil # just to have the table below pretty
	VALUES = {
		n => [ 0b000, 0b000, 0b000, 0b000, 0b000, ],
		0 => [ 0b111, 0b101, 0b101, 0b101, 0b111, ],
		1 => [ 0b010, 0b110, 0b010, 0b010, 0b010, ],
		2 => [ 0b111, 0b001, 0b111, 0b100, 0b111, ],
		3 => [ 0b111, 0b001, 0b111, 0b001, 0b111, ],
		4 => [ 0b101, 0b101, 0b111, 0b001, 0b001, ],
		5 => [ 0b111, 0b100, 0b111, 0b001, 0b111, ],
		6 => [ 0b100, 0b100, 0b111, 0b101, 0b111, ],
		7 => [ 0b111, 0b001, 0b001, 0b001, 0b001, ],
		8 => [ 0b111, 0b101, 0b111, 0b101, 0b111, ],
		9 => [ 0b111, 0b101, 0b111, 0b001, 0b001, ],
	}

	def initialize(hat, x, y, color, off_color = nil)
		off_color ||= Ws2812::Color.new(0, 0, 0)
		@hat, @x, @y, @color, @off_color = hat, x, y, color, off_color
	end
	attr_reader :hat
	attr_accessor :x, :y, :color, :off_color

	def show(value, do_show = false, &pixel_set)
		pixel_set ||= method(:default_pixel_set)
		raise ArgumentError, "invalid value" unless VALUES[value]
		0.upto(4) do |y|
			0.upto(2) do |x|
				if VALUES[value][y][2-x].zero?
					pixel_set.call(@hat,@x + x, @y + y, @off_color)
				else
					pixel_set.call(@hat,@x + x, @y + y, @color)
				end
			end
		end
		@hat.show if do_show
	end

	def default_pixel_set(hat, x, y, color)
		hat[x, y] = color
	end
	private :default_pixel_set
end

class TwoDigit
	def initialize(hat, x, y, color, off_color = nil)
		@tens = Digit.new(hat, x, y, color, off_color)
		@singles = Digit.new(hat, x + 4, y, color, off_color)
		@hat, @x, @y, @color = hat, x, y, color
		@leading_zero = false
	end
	attr_reader :hat, :x, :y, :color, :off_color
	attr_accessor :leading_zero

	def show(value, do_show = false, &pixel_set)
		tens_value = value / 10
		tens_value = nil unless @leading_zero
		@tens.show(tens_value, false, &pixel_set)
		@singles.show(value % 10, false, &pixel_set)
		@hat.show if do_show
	end

	def off_color
		@tens.off_color
	end

	def off_color=(val)
		@tens.off_color = @singles.off_color = val
	end

	def color=(val)
		@tens.color = @singles.color = val
	end

	def x=(val)
		@tens.x = val
		@singles.x = val + 4
	end

	def y=(val)
		@tens.y = @singles.y = val
	end
end

# Init
hat = Ws2812::UnicornHAT.new
hat.rotation = 180
red = Ws2812::Color.new(0xff, 0, 0)
green = Ws2812::Color.new(0, 0xff, 0)
h = TwoDigit.new(hat, 0, 0, red)
m = TwoDigit.new(hat, 1, 3, green)
m.leading_zero = true
red_ps = proc do |hat, x, y, color|
	oldc = hat[x, y]
	hat[x, y] = Ws2812::Color.new(color.r, oldc.g, oldc.b)
end
green_ps = proc do |hat, x, y, color|
	oldc = hat[x, y]
	hat[x, y] = Ws2812::Color.new(oldc.r, color.g, oldc.b)
end

begin
	loop do	
		t = Time.now
		h.show(t.hour, false, &red_ps)
		m.show(t.min, false, &green_ps)
		hat.show
		left = (59-t.sec)
		sleep left <= 0 ? 0 : left
	end
rescue Interrupt
end

# cleanup
hat.clear
