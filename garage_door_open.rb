#!/usr/bin/env ruby

#  Need to run as superuser

require 'wiringpi'
require_relative 'lib/range_sensor_average_method.rb'
require_relative 'lib/motion_detector_method'

def garage_open(gpio,pir,led_motion, period)
  # If there is motion assume it's OK to leave open, otherwise send an email/SMS and close soon (maybe 5 minutes, but will depend on safeguards)
  # Maybe send an email anyway
  if motion(gpio,pir,led_motion, period) == 0 # garage is open and there is no movement
    # Send message
    puts "Garage door is open and no one appears to be in the garage. #{timeHMS()}\nWill check again in a minute"
    sleep(60)
    if motion(gpio,pir,led_motion, period) == 0
      # Send message
     `curl http://textbelt.com/text -d number=3104189657 -d "message=Garage door is open and no one appears to be in the garage.\n#{Time.now.strftime("%A, %b %d, %l:%M %P")}\nSent from Raspberry Pi."`
      puts "Garage door is open and no one appears to be in the garage.\nGarage door will be closed or a message sent."
      # Later work on closing door
    end
  else
    # Maybe log and send notice when done
    puts "Garage door is open and someone appears to be in the garage, so no action will be taken."
  end
end

# detects motion for seconds (period). See motion_detector_method.rb for notes
def motion(gpio,pir,led_motion, seconds)
  pirVal = 0                          
  start = Time.now
  while (Time.now - start < seconds) and (pirVal == 0) 
    pirVal = gpio.read(pir)               # read input value. 1 if motion detected
    if pirVal == 1 # motion detected. LED on, and will exit loop
      gpio.write(led_motion, 1)                  # turn LED ON
    end
  end # while
  return pirVal
end

def timeHMS # time in format HH:MM:SS
  Time.now.strftime("%H:%M:%S")
end
############## Initialize gpio and variables
gpio = WiringPi::GPIO.new

# For proximity detector
trig       = 4 
echo       = 5
led_prox   = 1

# For motion detector
pir        = 11 # feedback from motion detector
led_motion = 6 # LED to be lit for a short time after motion detected
period     = 0.5 # second. Check for this long then check out. Report out if any motion during this period

# Overhead lights
led_lights = 8 # just an indicator
relay_lights = 9 # relay to turn lights on and off

###### Initialize pins for proximity  
gpio.mode(pir, INPUT) # feedback from motion detector. 
gpio.mode(led_prox, OUTPUT) # LED to be lit for a short time after motion detected

###### Initialize pins for motion detection
gpio.mode(trig, OUTPUT)
gpio.mode(echo, INPUT)
gpio.mode(led_motion, OUTPUT) # led is just an indicator. Not required for ultrasonic measurement

 

######

# start the indefinite loop  
#   #  Start a thread to Check for motion to turn on lights. If motion leave on for a while (maybe 30s), then check again for motion
Thread.new do
  loop do
    if motion(gpio,pir,led_motion, period) == 1
      gpio.write(relay_lights, 1) # Turn on lights
      gpio.write(led_lights, 1) # Turn on indicator light (not the same as motion indicator)
      puts "Motion detected, overhead lights on for 30 seconds.  #{timeHMS()}"
      # Turn on LED to indicate lights should be on
      sleep(30) # after turning on lights, leave them on 30 seconds
    else # turn off lights
      gpio.write(relay_lights, 0) # Turn off lights
      gpio.write(led_lights, 0) # Turn off LED indicator for lights
      # puts "No motion detected, overhead lights off.  #{timeHMS()}"  # get report several times per second
    end # if motion
  end # loop do for turning on the lights
end # Thread.new

loop do
  # Check if door is open, if open do stuff;

  gpio.write(led_prox, 0) # LED off to start
  gpio.write(led_motion, 0) # LED off to start

  distance = average_distance(gpio, trig, echo, led_prox) # Three measurements 2 seconds apart are averaged
  puts "Distance: #{distance.round(2)} m"

  if distance > 1.0 # meter
    puts "\nGarage Door Is Open\n"
    # Garage is open, so check if onyone is in the garage doing something
    garage_open(gpio,pir,led_motion, period)
  else
    puts "\nGarage Door Is Closed\n"
  end
end # loop do for garage door

