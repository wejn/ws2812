module Ws2812
	##
	# Simple wrapper class around RGB based color
	class Color
		def initialize(r, g, b)
			@r, @g, @b = r, g, b
		end
		attr :r, :g, :b

		##
		# Converts color to integer by encoding +r+, +g+, +b+
		# as 8bit values (in this order)
		#
		# Thus <tt>Color.new(1,2,3).to_i # => 66051</tt>
		def to_i
			((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff)
		end

		##
		# Converts color from integer +i+ by taking the least significant
		# 24 bits and using them for r(8), g(8), b(8); in this order.
		def self.from_i(i)
			Color.new((i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff)
		end


		# Makes sense to represent color as hex, right?
		def to_hex
			"#%02x%02x%02x" % [r & 0xff, g & 0xff, b & 0xff]
		end
		alias_method :to_s, :to_hex
	end
end
