module Ws2812
	VERSION = "0.0.1"
end

# to make it all less confusing
WS2812 = Ws2812

unless $__WS2812_SKIP_LL
	require 'ws2812/lowlevel'
end
require 'ws2812/color'
require 'ws2812/basic'
require 'ws2812/unicornhat'
