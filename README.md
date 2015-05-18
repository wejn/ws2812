# What's this
Ruby wrapper around WS2812 LED driver for Raspberry Pi.

Or, to be more specific, a Ruby gem that encapsulates modified RPi ws281x
library from UnicornHAT to help drive your WS2812 led chain (or matrix)
from Raspberry Pi.

These WS281x LEDs are sometimes also known as NeoPixels.

# Installation
As this is a published Ruby gem,
```
gem install ws2812
```
should be enough. But the examples will be hidden in 'gems' dir.

If you want to avoid the gem route, the following works just as well:
```
git clone https://github.com/wejn/ws2812
cd ws2812
# Assuming raspbian here; otherwise make sure you have 'mkmf'
# and can compile exts (failing that "rake compile" will bomb on you)
sudo apt-get update
sudo apt-get install -y ruby-full
# .
sudo gem install rake rake-compiler
rake compile
# and then, to demo it:
sudo ruby examples/digiclock.rb
```

# Examples
See the [examples](https://github.com/wejn/ws2812/tree/master/examples)
directory from the gem (or GH repo).

# License
GNU General Public License v. 2, see [LICENSE.txt](LICENSE.txt).

# Authors
This gem (all of the ruby code and some tweaks to the C extension) was
created by Michal Jirků <box@wejn.org>.

And it wouldn't be possible without the original UnicornHAT repo.

From that repo I not only took inspiration when it comes to the interface,
but I also also translated bits and pieces from Python to Ruby.

And, in turn, the UnicornHAT repo wouldn't be possible without
Richard Hirst's modification of Jeremy Garff's RPi ws281x library.

Thanks to you both.

## Links
* [Pimoroni's UnicornHAT](https://github.com/pimoroni/unicorn-hat)
* [RPi ws281x mod by Jeremy Garff](https://github.com/jgarff/rpi_ws281x)
* [Original RPi ws281x library](https://github.com/richardghirst/rpi_ws281x)
