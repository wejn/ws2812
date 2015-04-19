module Ws2812
	##
	# Provides basic interface for so called NeoPixels (ws2812 RGB LED
	# chips)
	#
	# This library internally uses C (and SWIG) extension from Richard Hirst's
	# version of Jeremy Garff's rpi_ws281x library.
	#
	# And this particular class is heavily inspired by the included
	# <tt>neopixel.py</tt> Python class within these projects.
	#
	# See:
	# [jgarff]        https://github.com/jgarff/rpi_ws281x
	# [richardghirst] https://github.com/richardghirst/rpi_ws281x
	# [pimoroni]      https://github.com/pimoroni/unicorn-hat/tree/master/python/rpi-ws281x
	#
	#
	class Basic
		include Ws2812::Lowlevel

		##
		# Initializes the basic ws2812 driver for +num+ leds at given +pin+,
		# with initial +brightness+ (0..255)
		#
		# The +options+ hash can contain various additional options
		# (all keys as symbols):
		#
		# [freq]    frequency (Hz) to communicate at, defaults to 800_000
		# [dma]     dma channel to use, defaults to 5
		# [invert]  use inverted logic, defaults to false
		# [channel] which channel to use, defaults to 0 (permissible 0, 1)
		def initialize(num, pin, brightness = 50, options = {})

			freq = options.fetch(:freq) { 800_000 }
			dma = options.fetch(:dma) { 5 }
			invert = options.fetch(:invert) { false }
			channel = options.fetch(:channel) { 0 }

			@leds = Ws2811_t.new
			@leds.freq = freq
			@leds.dmanum = dma

			@channel = ws2811_channel_get(@leds, channel)
			@channel.count = num
			@channel.gpionum = pin
			@channel.invert = invert ? 1 : 0
			@channel.brightness = brightness

			@count = num

			at_exit { self.close }

			@open = false
		end

		##
		# Actually opens (initializes) communication with the LED strand
		#
		# Raises an exception when the initialization fails.
		#
		# Failure is usually because you don't have root permissions
		# which are needed to access /dev/mem and to create special
		# devices.
		def open
			return nil if @open
			resp = ws2811_init(@leds)
			fail "init failed with code: " + resp.to_s + ", perhaps you need to run as root?" unless resp.zero?
			@open = true
			self
		end

		##
		# Closes (deinitializes) communication with the LED strand
		#
		# Can be called on already closed device just fine
		def close
			if @open && @leds
				@open = false
				ws2811_fini(@leds)
				@channel = nil # will GC the memory
				@leds = nil
				# Note: ws2811_fini will free mem used by led_data internally
			end
			self
		end


		##
		# Apply all changes since last show
		#
		# This method renders all changes (brightness, pixels) done to the
		# strand since last show
		def show
			resp = ws2811_render(@leds)
			fail "show failed with code: " + resp.to_s unless resp.zero?
		end

		##
		# Set given pixel identified by +index+ to +color+
		#
		# See +set+ for a method that takes individual +r+, +g+, +b+
		# components
		def []=(index, color)
			if index.respond_to?(:to_a)
				index.to_a.each do |i|
					check_index(i)
					ws2811_led_set(@channel, i, color.to_i)
				end
			else
				check_index(index)
				ws2811_led_set(@channel, index, color.to_i)
			end
		end

		##
		# Set given pixel identified by +index+ to +r+, +g+, +b+
		#
		# See <tt>[]=</tt> for a method that takes +Color+ instance instead
		# of individual components
		def set(index, r, g, b)
			check_index(index)
			self[index] = Color.new(r, g, b)
		end

		##
		# Set brightness used for all pixels
		#
		# The value is from +0+ to +255+ and is internally used as a scaler
		# for all colors values that are supplied via <tt>[]=</tt>
		def brightness=(val)
			@channel.brightness = val
		end

		##
		# Return brightness used for all pixels
		#
		# The value is from +0+ to +255+ and is internally used as a scaler
		# for all colors values that are supplied via <tt>[]=</tt>
		def brightness
			@channel.brightness
		end

		##
		# Number of leds it's initialized for
		#
		# Method actually passes to low-level implementation for this
		# value; it doesn't use the parameter passed during construction
		def count
			@channel.count
		end

		##
		# Return +Color+ of led located at given index
		#
		# Indexed from 0 upto <tt>#count - 1</tt>
		def [](index)
			if index.respond_to?(:to_a)
				index.to_a.map do |i|
					check_index(i)
					Color.from_i(ws2811_led_get(@channel, i))
				end
			else
				check_index(index)
				Color.from_i(ws2811_led_get(@channel, index))
			end
		end

		##
		# Verify supplied index
		#
		# Raises ArgumentError if the supplied index is invalid
		# (doesn't address configured pixel)
		def check_index(index)
			if 0 <= index && index < @count
				true
			else
				fail ArgumentError, "index #{index} outside of permitted range [0..#{count})"
			end
		end
		private :check_index
	end
end
