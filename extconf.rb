require 'mkmf'
#$libs = append_library($libs, "lib/libws2812-RPi.a")
find_library('ws2812-RPi', 'init', 'lib')
create_makefile 'ws2812'
