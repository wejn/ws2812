#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812'

class Digit
	n = nil # just to have the table below pretty
	VALUES = {
		n => [ 0b000, 0b000, 0b000, 0b000, 0b000, ],
		0 => [ 0b111, 0b101, 0b101, 0b101, 0b111, ],
		#1 => [ 0b010, 0b110, 0b010, 0b010, 0b010, ], # 1 in the middle
		1 => [ 0b001, 0b011, 0b001, 0b001, 0b001, ], # 1 at the left
		2 => [ 0b111, 0b001, 0b111, 0b100, 0b111, ],
		3 => [ 0b111, 0b001, 0b111, 0b001, 0b111, ],
		4 => [ 0b101, 0b101, 0b111, 0b001, 0b001, ],
		5 => [ 0b111, 0b100, 0b111, 0b001, 0b111, ],
		#6 => [ 0b111, 0b100, 0b111, 0b101, 0b111, ], # "full" six
		6 => [ 0b100, 0b100, 0b111, 0b101, 0b111, ], # "sparse" six
		7 => [ 0b111, 0b001, 0b001, 0b001, 0b001, ],
		8 => [ 0b111, 0b101, 0b111, 0b101, 0b111, ],
		#9 => [ 0b111, 0b101, 0b111, 0b001, 0b111, ], # "full" nine
		9 => [ 0b111, 0b101, 0b111, 0b001, 0b001, ], # "sparse" nine
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

class TwoDigits
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
		tens_value = nil if !@leading_zero && tens_value.zero?
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

if __FILE__ == $0
	# Init
	hat = Ws2812::UnicornHAT.new
	hat.rotation = 180

	gc = Ws2812::GammaCorrection.new(20)
	hat.direct = true
	black = gc.correct(Ws2812::Color.new(0, 0, 0))
	red = gc.correct(Ws2812::Color.new(0xff, 0, 0))
	green = gc.correct(Ws2812::Color.new(0, 0xaa, 0))
	both = gc.correct(Ws2812::Color.new(0xff, 0xaa, 0))
	h = TwoDigits.new(hat, 0, 0, red, black)
	m = TwoDigits.new(hat, 1, 3, green, black)
	m.leading_zero = true

	green_ps = proc do |hat, x, y, color|
		if hat[x, y] == red
			hat[x, y] = both if color == green
			# otherwise stays red
		else
			hat[x, y] = color
		end
	end

	begin
		ticks = 25
		tick = 0
		direction = 1
		ot = nil
		loop do	
			t = Time.now

			# set the display anew if hour/minute changed
			if ot.nil? || (ot.hour != t.hour || ot.min != t.min)
				ot = t
				hat.clear(false)
				h.show(t.hour, false)
				m.show(t.min, false, &green_ps)
			end


			# animate "both" pixels (where hour & minute overlay)
			both.r = (red.r * tick.to_f/ticks).to_i
			both.g = (green.g * ((ticks - tick).to_f/ticks)).to_i
			both.r = both.g = 1 if both.r.zero? && both.g.zero?
			hat.push_all_pixels

			if direction > 0
				direction = -1 if tick + 1 >= ticks
				tick = tick + 1
			else
				direction = 1 if tick - 1 <= 0
				tick = tick - 1
			end

			hat.show
			sleep 0.1
		end
	rescue Interrupt
	end

	# cleanup
	hat.clear
end
