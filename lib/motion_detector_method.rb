#!/usr/bin/env ruby

# Checks for motion for 'seconds'. Quits and reports when motion detected or after 'seconds'.
#  PIR = Passive Infrared Sensor 

#  THIS IS CALLED BY ANOTHER SCRIPT

require 'wiringpi'

# Initialize outside since other gpios may be involved 
# gpio = WiringPi::GPIO.new
#
# pir = 11 # feedback from motion detector
# led = 6 # LED to be lit for a short time after motion detected
# period = 5 # second. Check for this long then check out. Report out if any motion during this period
#
# gpio.write(led, 0) # LED off to start
#
# gpio.mode(pir, INPUT) # feedback from motion detector.
# gpio.mode(led, OUTPUT) # LED to be lit for a short time after motion detected

def motion(gpio,pir,led, seconds)
  pirVal = 0                          # we start, assuming no motion detected
  start = Time.now
  # puts "start: #{start}"
  # puts "Time.now: #{Time.now}"
  while (Time.now - start < seconds) and (pirVal == 0) # or doesn't work. Don't understand why.
    # len = (Time.now - start).strftime("%M:%S.%6L") # undefined method `strftime'
    # puts "How long (min:sec): #{len}"
    pirVal = gpio.read(pir)               # read input value. 1 if motion detected
    if pirVal == 1 # motion detected. LED on, and will exit loop
      gpio.write(led, 1)                  # turn LED ON
    end
  end # while
  return pirVal
end

# These work for stand alone script
# pirVal = motion(gpio,pir,led, period)
# if pirVal == 1
#   puts "Motion detected. pirVal: #{pirVal}"
# else
#   puts "No motion detected. pirVal: #{pirVal}"
# end
# gpio.write(led, 0)