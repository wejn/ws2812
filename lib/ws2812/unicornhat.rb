module Ws2812
	##
	# Provides interface for *Unicorn HAT* (a 8x8 ws2812 matrix by Pimoroni)
	#
	# This particular class is heavily inspired by the <tt>unicornhat.py</tt>
	# class from UnicornHat's repo.
	#
	# See:
	# [unicornhat] https://github.com/pimoroni/unicorn-hat
	#
	class UnicornHAT
		UHAT_MAP = [
			[7 ,6 ,5 ,4 ,3 ,2 ,1 ,0 ],
			[8 ,9 ,10,11,12,13,14,15],
			[23,22,21,20,19,18,17,16],
			[24,25,26,27,28,29,30,31],
			[39,38,37,36,35,34,33,32],
			[40,41,42,43,44,45,46,47],
			[55,54,53,52,51,50,49,48],
			[56,57,58,59,60,61,62,63]
		]
		##
		# Initializes the matrix ws2812 driver at given +pin+,
		# with initial +brightness+ (0..255)
		#
		# The +options+ hash can contain various additional options,
		# see +Basic+ class' description of options for more details.
		def initialize(pin = 18, brightness = 50, options = {})
			@hat = Basic.new(64, pin, brightness, options)
			@hat.open

			@rotation = 0
			@pixels = Array.new(8) { |x| Array.new(8) { |y| Color.new(0,0,0) } }
			push_all_pixels
		rescue Object
			@hat = nil
			raise
		end

		##
		# Closes (deinitializes) communication with the matrix
		#
		# Can be called on already closed device just fine
		def close
			if @hat
				@hat.close
				@hat = nil
			end
			self
		end

		##
		# Apply all changes since last show
		#
		# This method renders all changes (brightness, pixels, rotation)
		# done to the strand since last show
		def show
			@hat.show
		end

		##
		# Set given pixel identified by +x+, +y+ to +color+
		#
		# See +set+ for a method that takes individual +r+, +g+, +b+
		# components.
		#
		# You still have to call +show+ to make the changes visible.
		def []=(x, y, color)
			check_coords(x, y)
			@pixels[x][y] = color
			@hat[map_coords(x, y)] = color
		end

		##
		# Set given pixel identified by +x+, +y+ to +r+, +g+, +b+
		#
		# See <tt>[]=</tt> for a method that takes +Color+ instance instead
		# of individual components.
		#
		# You still have to call +show+ to make the changes visible.
		def set(x, y, r, g, b)
			check_coords(x, y)
			self[x, y] = Color.new(r, g, b)
		end

		##
		# Set brightness used for all pixels
		#
		# The value is from +0+ to +255+ and is internally used as a scaler
		# for all colors values that are supplied via <tt>[]=</tt>
		#
		# You still have to call +show+ to make the changes visible.
		def brightness=(val)
			@hat.brightness = val
		end

		##
		# Return brightness used for all pixels
		#
		# The value is from +0+ to +255+ and is internally used as a scaler
		# for all colors values that are supplied via <tt>[]=</tt>
		def brightness
			@hat.brightness
		end

		##
		# Return +Color+ of led located at given +x+, +y+
		def [](x, y)
			@pixels[x][y]
		end

		##
		# Returns current rotation as integer; one of: [0, 90, 180, 270]
		def rotation
			@rotation
		end

		##
		# Set rotation of the Unicorn HAT to +val+
		#
		# Permissible values for rotation are [0, 90, 180, 270] (mod 360).
		#
		# You still have to call +show+ to make the changes visible.
		def rotation=(val)
			permissible = [0, 90, 180, 270]
			fail ArgumentError, "invalid rotation, permissible: #{permissible.join(', ')}" unless permissible.include?(val % 360)
			@rotation = val % 360
			push_all_pixels
		end

		##
		# Clears all pixels (sets them to black) and calls +show+ if +do_show+
		def clear(do_show = true)
			set_all(Color.new(0, 0, 0))
			show if do_show
		end

		##
		# Sets all pixels to +color+
		#
		# You still have to call +show+ to make the changes visible.
		def set_all(color)
			0.upto(7) do |x|
				0.upto(7) do |y|
					self[x, y] = color
				end
			end
		end

		##
		# Pushes all pixels from buffer to the lower level (physical device)
		def push_all_pixels
			0.upto(7) do |x|
				0.upto(7) do |y|
					@hat[map_coords(x, y)] = @pixels[x][y]
				end
			end
		end
		private :push_all_pixels


		##
		# Maps +x+, +y+ coordinates to index on the physical matrix
		# (takes rotation into account)
		def map_coords(x, y)
			check_coords(x, y)
			y = 7 - y
			case rotation
			when 90
				x, y = y, 7 - x
			when 180
				x, y = 7 - x, 7 - y
			when 270
				x, y = 7 - y, x
			end

			UHAT_MAP[x][y]
		end
		private :map_coords

		##
		# Verify supplied coords +x+ and +y+
		#
		# Raises ArgumentError if the supplied coords are invalid
		# (doesn't address configured pixel)
		def check_coords(x, y)
			if 0 <= x && x < 8 && 0 <= y && y < 8
				true
			else
				fail ArgumentError, "coord (#{x},#{y}) outside of permitted range ((0..7), (0..7))"
			end
		end
		private :check_coords
	end
end
