#!/bin/bash

# Copyright 2018 Marc René Schädler
#
# This file is part of the mobile hearing aid prototype project
# The the mobile hearing aid prototype project is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# The mobile hearing aid prototype project is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with the mobile hearing aid prototype project. If not, see http://www.gnu.org/licenses/.

# Simple sound configuration
SOUNDDEVICE=audioinjectorpi
SOUNDSTREAM=0
SOUNDCHANNELS=1,2
SAMPLERATE=48000
FRAGSIZE=48
NPERIODS=2

echo ""
echo "MEASURE FEEDBACK (CANCELLATION) WITH HEARING AID PROTOTYPE"
echo ""

echo "killall pink noise"
killall pinknoise -9 &> /dev/null

echo "killall abhang"
killall abhang -9 &> /dev/null

echo "killall mha"
killall mha -9 &> /dev/null

echo "killall jackd"
killall jackd -9 &> /dev/null

sleep 1

echo "start jackd"
taskset -c 1 jackd --realtime -d alsa -d hw:$SOUNDDEVICE,$SOUNDSTREAM -p $FRAGSIZE -r $SAMPLERATE -n $NPERIODS -s 2>&1 | sed 's/^/[JACKD] /' &
sleep 2

echo "start pink noise"
(cd tools/signals && ./pinknoise) 2>&1 &
sleep 0.5

jack_connect pinknoise:output_1 system:playback_2
jack_connect pinknoise:output_2 system:playback_1

echo "record feedback"
jack_rec -f "/tmp/feedback.wav" -d 10 -b 32 pinknoise:output_1 pinknoise:output_2 system:capture_1 system:capture_2

echo "stop pink noise"
killall pinknoise -9 &> /dev/null

echo "calculate feedback path"
(cd tools/ && taskset -c 0 nice ./update_abhang_configuration.m)

echo "start static feedback cancelation"
(cd tools/abhang/src/jack && taskset -c 2 ./abhang) 2>&1 &
sleep 1

# Connections
echo "Wireing..."
jack_connect system:capture_1 abhang:input_1
jack_connect system:capture_2 abhang:input_2
echo "RUNNING!"

# Measure compensated feedback in loop
COUNT=0
while true; do
  COUNT=$[$COUNT+1]
  echo "start pink noise"
  (cd tools/signals && ./pinknoise) 2>&1 &
  sleep 0.5

  jack_connect pinknoise:output_1 abhang:input_3
  jack_connect pinknoise:output_1 system:playback_2
  jack_connect pinknoise:output_2 abhang:input_4
  jack_connect pinknoise:output_2 system:playback_1

  echo "record feedback"
  jack_rec -f "/tmp/feedback_${COUNT}.wav" -d 10 -b 32 pinknoise:output_1 pinknoise:output_2 abhang:output_1 abhang:output_2
  
  echo "stop pink noise"
  killall pinknoise -9 &> /dev/null

  sleep 10
done



