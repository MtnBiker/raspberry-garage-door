#  See range_sensor_wiringpi for details, htis is stripped down

#  Sensor needs big target, gets confused other wise.

#  WiringPi uses its own pin numbering scheme
# require 'wiringpi'

def measure(gpio, trig, echo, led)
  # puts "Distance Measurement In Progress"

  gpio.write(led, 0)
  gpio.write(trig, 0)
  # puts "Waiting 2 Seconds For Sensor To Settle"
  sleep(2)

  gpio.write(led, 1) # turn on led for pulse duration
  #  Send pulse
  gpio.write(trig, 1) # start pulse
  # puts "31. wrote trigger"
  gpio.write(led, 0)
  sleep(0.00001) # pulse 10 µsec minimum. 
  gpio.write(trig, 0) # end of pusle

  while gpio.read(echo) == 0
    pulse_start = Time.now # last time through loop is the start of the return pulse
  end

  # Once a signal is received, the value changes from low (0) to high (1 ) and the signal will remain high for the duration of the echo pulse. We therefore also need the last high timestamp for echo (pulse_end):
  while gpio.read(echo) == 1
      pulse_end = Time.now
  end

  # We can now calculate the difference between the two recorded timestamps and hence the duration of the pulse (pulse_duration):

  pulse_duration = pulse_end - pulse_start

  distance = pulse_duration * 171.50 # 171.5 for m, 17150 for cm

  # puts "\nDistance: #{distance.round(3)} m"
  return distance
end

def average_distance(gpio, trig, echo, led)
  puts "\nDistance Measurement In Progress. Three measurements 2 seconds apart will be averaged."
  distance = 0
  distance = measure(gpio, trig, echo, led)
  sleep(0.1)
  distance += measure(gpio, trig, echo, led)
  sleep(0.1)
  distance += measure(gpio, trig, echo, led)
  distance = distance / 3
  # return distance
end

# The following is needed if run from this script, otherwise do this stuff elsewhere if doing repeated measurement
def report_distance(trig, echo, led)
  # initialize the GPIO port
  gpio = WiringPi::GPIO.new
  
  gpio.mode(trig, OUTPUT)
  gpio.mode(echo, INPUT)
  gpio.mode(led, OUTPUT) # led is just an indicator. Not required for ultrasonic measurement

  distance = average_distance(gpio, trig, echo, led)
  # puts "\nDistance average of three: #{distance.round(2)} m"
  return distance
end

#  This all should probably be a class
# trig = 4
# echo = 5
# led = 6


