module Ws2812
	VERSION = "0.0.4"
end

# to make it all less confusing
WS2812 = Ws2812

if $__WS2812_SKIP_LL
	module Ws2812
		module Lowlevel
			# XXX: could provide full blown emulation of all calls? :)
		end
	end
else
	require 'ws2812/lowlevel'
end
require 'ws2812/color'
require 'ws2812/basic'
require 'ws2812/unicornhat'
require 'ws2812/gamma_correction'
