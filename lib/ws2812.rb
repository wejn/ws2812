module Ws2812
	VERSION = "0.0.1"
end

unless $__WS2812_SKIP_LL
	require 'ws2812/lowlevel'
end
require 'ws2812/color'
require 'ws2812/basic'
