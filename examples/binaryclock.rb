#!/usr/bin/env ruby
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ws2812'

# Single 1x4 pixels binary "digit"
class BinaryDigit
	def initialize(hat, x, y, color, off_color = nil)
		off_color ||= Ws2812::Color.new(0, 0, 0)
		@hat, @x, @y, @color, @off_color = hat, x, y, color, off_color
	end
	attr_reader :hat
	attr_accessor :x, :y, :color, :off_color

	def show(value, do_show = false, &pixel_set)
		pixel_set ||= method(:default_pixel_set)
		raise ArgumentError, "invalid value" unless (0..9).include?(value)
		x = 0
		0.upto(3) do |y|
			if value[3-y].zero?
				pixel_set.call(@hat,@x + x, @y + y, @off_color)
			else
				pixel_set.call(@hat,@x + x, @y + y, @color)
			end
		end
		@hat.show if do_show
	end

	def default_pixel_set(hat, x, y, color)
		hat[x, y] = color
	end
	private :default_pixel_set
end

# Two BinaryDigits next to each other with no pixel gap
class TwoBinaryDigits
	def initialize(hat, x, y, color, off_color = nil)
		@tens = BinaryDigit.new(hat, x, y, color, off_color)
		@singles = BinaryDigit.new(hat, x + 1, y, color, off_color)
		@hat, @x, @y, @color = hat, x, y, color
	end
	attr_reader :hat, :x, :y, :color, :off_color

	def show(value, do_show = false, &pixel_set)
		tens_value = value / 10
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
		@singles.x = val + 1
	end

	def y=(val)
		@tens.y = @singles.y = val
	end
end

# A 6x4 matrix that represents binary clock
class BinaryClock
	def initialize(hat, x, y, color)
		@h = TwoBinaryDigits.new(hat, x, y, color)
		@m = TwoBinaryDigits.new(hat, x+2, y, color)
		@s = TwoBinaryDigits.new(hat, x+4, y, color)
	end

	def show(time)
		@h.show(time.hour, false)
		@m.show(time.min, false)
		@s.show(time.sec, false)
	end
end

# A 8x4 matrix that represents binary calendar (ddmmyyyy)
class BinaryCalendar
	def initialize(hat, x, y, color)
		@d = TwoBinaryDigits.new(hat, x, y, color)
		@m = TwoBinaryDigits.new(hat, x+2, y, color)
		@y1 = TwoBinaryDigits.new(hat, x+4, y, color)
		@y2 = TwoBinaryDigits.new(hat, x+6, y, color)
	end

	def show(time)
		@d.show(time.day, false)
		@m.show(time.month, false)
		@y1.show(time.year/100, false)
		@y2.show(time.year%100, false)
	end
end

if __FILE__ == $0
	# Init
	hat = Ws2812::UnicornHAT.new
	hat.rotation = 180
	hat.brightness = 20

	frame = Ws2812::Color.new(0x00, 0x00, 0x66)
	red = Ws2812::Color.new(0xff, 0, 0)
	green = Ws2812::Color.new(0, 0xff, 0)
	if true
		# Calendar + Clock
		calendar = BinaryCalendar.new(hat, 0, 0, green)
		clock = BinaryClock.new(hat, 1, 4, red)
		show_calendar = true
		frame_proc = proc do
			4.upto(7) do |y|
				hat[0, y] = hat[7, y] = frame
			end
		end
	else
		# Just clock, with a frame around it
		clock = BinaryClock.new(hat, 1, 2, red)
		show_calendar = false
		frame_proc = proc do
			0.upto(7) do |x|
				#hat[x, 7] = hat[x, 0] = frame
				hat[x, 6] = hat[x, 1] = frame
			end
			2.upto(5) do |y|
				hat[0, y] = hat[7, y] = frame
			end
		end
	end
	ot = nil

	# Show it...
	begin
		loop do	
			t = Time.now

			# set the display anew if hour/minute/sec changed
			if ot.nil? || (ot.hour != t.hour || ot.min != t.min || ot.sec != t.sec)
				ot = t
				hat.clear(false)
				clock.show(t)
				calendar.show(t) if show_calendar
				frame_proc.call
				hat.show
			end

			sleep 0.1
		end
	rescue Interrupt
	end

	# cleanup
	hat.clear
end
