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

class GammaCorrection
	# correction table thanks to http://rgb-123.com/ws2812-color-output/
	GAMMA_TABLE = [
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2,
		2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5,
		6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 11, 11,
		11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18,
		19, 19, 20, 21, 21, 22, 22, 23, 23, 24, 25, 25, 26, 27, 27, 28,
		29, 29, 30, 31, 31, 32, 33, 34, 34, 35, 36, 37, 37, 38, 39, 40,
		40, 41, 42, 43, 44, 45, 46, 46, 47, 48, 49, 50, 51, 52, 53, 54,
		55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
		71, 72, 73, 74, 76, 77, 78, 79, 80, 81, 83, 84, 85, 86, 88, 89,
		90, 91, 93, 94, 95, 96, 98, 99,100,102,103,104,106,107,109,110,
		111,113,114,116,117,119,120,121,123,124,126,128,129,131,132,134,
		135,137,138,140,142,143,145,146,148,150,151,153,155,157,158,160,
		162,163,165,167,169,170,172,174,176,178,179,181,183,185,187,189,
		191,193,194,196,198,200,202,204,206,208,210,212,214,216,218,220,
		222,224,227,229,231,233,235,237,239,241,244,246,248,250,252,255
	]

	def initialize(brightness)
		self.brightness = brightness
	end

	def brightness=(value)
		raise ArgumentError, "brightness should be within (0..255)" unless (0..255).include?(value.to_i)
		@brightness = value.to_i
	end
	attr_reader :brightness

	def correct(value)
		if value.kind_of?(Ws2812::Color)
			Ws2812::Color.new(
				self.correct(value.r),
				self.correct(value.g),
				self.correct(value.b))
		else
			raise ArgumentError, "value should be within (0..255)" unless (0..255).include?(value.to_i)
			(GAMMA_TABLE[value.to_i] * (@brightness + 1)) >> 8
		end
	end

	def correct_with_min_max(value, min = nil, max = nil)
		trim(correct(value), min, max)
	end

	def trim(value, min = nil, max = nil)
		if value.kind_of?(Ws2812::Color)
			Ws2812::Color.new(
				self.trim(value.r, min && min.r, max && max.r),
				self.trim(value.g, min && min.g, max && max.g),
				self.trim(value.b, min && min.b, max && max.b))
		else
			if min && value.to_i < min.to_i
				min.to_i
			elsif max && value.to_i > max.to_i
				max.to_i
			else
				value.to_i
			end
		end
	end
end

if __FILE__ == $0
	# Init
	hat = Ws2812::UnicornHAT.new
	hat.rotation = 180

	gc = GammaCorrection.new(20)
	hat.direct = true
	black = gc.correct(Ws2812::Color.new(0, 0, 0))
	red = gc.correct(Ws2812::Color.new(0xff, 0, 0))
	green = gc.correct(Ws2812::Color.new(0, 0xaa, 0))
	both = gc.correct(Ws2812::Color.new(0xff, 0xaa, 0))
	h = TwoDigit.new(hat, 0, 0, red, black)
	m = TwoDigit.new(hat, 1, 3, green, black)
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
