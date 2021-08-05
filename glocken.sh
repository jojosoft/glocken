#!/bin/bash

# glocken - Simulation of the church bells in Entringen (Germany).
# Copyright (C) 2021 Johannes Schirm

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

# Take the current time as the first argument.
# It needs to be in 24-hour HH:MM format.
# If not passed, use the current time.
if [[ "$#" -lt 1 ]]
then
	TIME=$(date "+%H:%M")
else
	TIME=$1
fi
# Split the time into hours and minutes.
HOUR=$(echo "${TIME%:*}" | bc -l)
MINUTE=$(echo "${TIME#*:}" | bc -l)

# Set working directory to script location.
cd "$(dirname "$0")"

# Main playback function for audio samples.
# Forks a separate audio player for each sample.
# Expects the file to play in $1.
function sample {
	# No volume adjustment...
	#aplay --quiet $1 &
	# Stops working when called through cron, even with black magic...
	#XDG_RUNTIME_DIR=/run/user/1000 paplay --volume 39322 --stream-name Glocken &
	# Only working solution in the universe is sox, which requires black magic...
	# Black magic wizard has the solution: https://stackoverflow.com/a/43436895
	# (The -t alsa is to avoid unnecessary, vapid error messages, don't even ask.)
	# Set volume to 25% for background playback, like at some place in the village.
	# (PulseAudio will still show 100% because it is applied before.)
	XDG_RUNTIME_DIR=/run/user/$(id -u $(whoami)) play -q -v 0.25 "$1" -t alsa &
	# Works to some degree, too, but in total sucks a bit more than sox.
	#mplayer -really-quiet -ao pulse -volume 60 "$1" 2> /dev/null &
}
# Functions to asynchronously play one sample.
# Returns exactly when succeeding samples need to start playing.
function quarterloop {
	echo "Quarter"
	sample Zwischenschlag\ \(Loop\).wav
	sleep 2.401
}
function quarterbridge {
	echo "Quarter"
	sample Zwischenschlag\ \(Übergang\).wav
	sleep 3.807
}
function quarterend {
	echo "Quarter"
	sample Zwischenschlag\ \(Ende\).wav
}
function hourhighloop {
	echo "Hour (High)"
	sample Bim\ \(Loop\).wav
	sleep 2.018
}
function hourhighbridge {
	echo "Hour (High)"
	sample Bim\ \(Übergang\).wav
	sleep 4.090
}
function hourlowloop {
	echo "Hour (Low)"
	sample Bam\ \(Loop\).wav
	sleep 2.464
}
function hourlowend {
	echo "Hour (Low)"
	sample Bam\ \(Ende\).wav
}
# General function for chiming a certain bell.
# (Swinging it back and forth on special occasions.)
# This only considers the looping part!
function chime {
	# Argument $1 is the file path to the loop sample.
	# $2 needs to contain the loop delay in seconds.
	# $3 contains the total play time in seconds.
	# Note: Depending on $2, the total play time may vary.
	# Only full samples are played, so rounding happens.
	# Optional: Alternative loop delay for the last loop in $4.
	LOOPS=$(bc -l <<< "secs = $3 / $2 + 0.5; scale = 0; secs / 1")
	if [[ "$LOOPS" -gt 0 ]]
	then
		for ((i = 1; i < LOOPS; i++))
		do
			sample "$1" &
			sleep $2
		done
		sample "$1" &
		if [[ "$#" -ge 4 ]]
		then
			sleep $4
		else
			sleep $2
		fi
	fi
}
# Specific functions for chiming each bell.
# $1 must contain the desired total play time in seconds.
# (Note that swing-in and swing-out will be added on top!)
# To add realistic swing-in times, set $2 to "delay".
function schiedglocke {
	echo "Schiedglocke"
	if [[ "$#" -ge 2 && $2 == "delay" ]]
	then
		sleep 14.618
	fi
	sample Schiedglocke\ \(Start\).wav
	sleep 12.153
	chime Schiedglocke\ \(Loop\).wav 3.530 $1
	sample Schiedglocke\ \(Ende\).wav
}
function dominika {
	echo "Dominika"
	if [[ "$#" -ge 2 && $2 == "delay" ]]
	then
		sleep 19.964
	fi
	sample Dominika\ \(Start\).wav
	sleep 21.024
	chime Dominika\ \(Loop\).wav 4.850 $1
	sample Dominika\ \(Ende\).wav
}
function betglocke {
	echo "Betglocke"
	if [[ "$#" -ge 2 && $2 == "delay" ]]
	then
		sleep 15.715
	fi
	sample Betglocke\ \(Start\).wav
	sleep 11.760
	chime Betglocke\ \(Loop\).wav 4.471 $1
	sample Betglocke\ \(Ende\).wav
}
function kreuzglocke {
	echo "Kreuzglocke"
	if [[ "$#" -ge 2 && $2 == "delay" ]]
	then
		sleep 14.790
	fi
	sample Kreuzglocke\ \(Start\).wav
	sleep 16.850
	chime Kreuzglocke\ \(Loop\).wav 1.987 $1 1.698
	sample Kreuzglocke\ \(Ende\).wav
}
function sunday {
	echo "Sounding bells to ring in Sunday!"
	if [[ "$#" -ge 2 && $2 == "delay" ]]
	then
		sleep 29.472
	fi
	sample Samstag\ \(Start\).wav
	sleep 73.741
	chime Samstag\ \(Loop\).wav 59.740 $1
	sample Samstag\ \(Ende\).wav
}


# Main
if [[ "$1" == "chime" ]]
then
	# For debugging, it is possible to chime individual bells.
	if [[ "$#" -lt 2 ]]
	then
		# With no parameter, just start ringing in Sunday for 0 minutes.
		# Start and then, once all bells are on full speed, stop.)
		sunday 0
	else
		# A specific bell has been requested, use the official index:
		# 9: Osanna
		# 8: Michaelsglocke
		# 7: Taufglocke
		# 6: Schiedglocke
		# 5: Zeichenglocke
		# 4: Kreuzglocke
		# 3: Ave Maria (Kleine Betglocke)
		# 2: Betglocke
		# 1: Dominika (Christusglocke)
		# NOTE! Only 6, 4, 2 and 1 are currently available!
		# The other bells are only used on special ocasions.
		# For this kind of request, chime any bell for 5 seconds.
		if [[ "$2" -eq 6 ]]
		then
			schiedglocke 5
		elif [[ "$2" -eq 4 ]]
		then
			kreuzglocke 5
		elif [[ "$2" -eq 2 ]]
		then
			betglocke 5
		elif [[ "$2" -eq 1 ]]
		then
			dominika 5
		fi
	fi
elif [[ $(( MINUTE % 15 )) -eq 0 ]]
then
	# The script activates for minutes 15, 30, 45 and 0.
	# Define the number of quarters for 0 to be 4 (full).
	QUARTERS=$(( MINUTE == 0 ? 4 : MINUTE / 15 ))
	for ((i = 1; i < QUARTERS; i++))
	do
		quarterloop
	done
	if [[ $QUARTERS -eq 4 ]]
	then
		quarterbridge
		# For full hours, play the according number of strokes.
		STROKES=$(( HOUR % 12 == 0 ? 12 : HOUR % 12 ))
		for ((i = 1; i < STROKES; i++))
		do
			hourhighloop
		done
		hourhighbridge
		for ((i = 1; i < STROKES; i++))
		do
			hourlowloop
		done
		hourlowend
		# Since it's a full hour, check if we should chime a bell!
		# Determine additional date information needed for this decision.
		WEEKDAY=$(date "+%u")
		DECDATE=$(echo $(date "+%m%d") | bc -l)
		if [[ $HOUR -eq 12 ]]
		then
			# Everyday on noon, chime the largest bell.
			dominika 100 delay
		elif [[ $HOUR -eq 17 && $WEEKDAY -eq 6 ]]
		then
			# Each Saturday evening at 5pm, ring in Sunday..!
			sunday 540 delay
		elif [[ $HOUR -eq 6 && ! $WEEKDAY -eq 7 ]]
		then
			# Morning chime on weekdays at 6am.
			betglocke 140 delay
		elif [[ $HOUR -eq 11 && ($WEEKDAY -le 4 || $WEEKDAY -eq 6) ]]
		then
			# Normal 11am chime on weekdays except Friday.
			schiedglocke 110 delay
		elif [[ $HOUR -eq 11 && $WEEKDAY -le 5 ]]
		then
			# Special 11am chime on Friday.
			kreuzglocke 110 delay
		elif [[ $HOUR -eq 15 && ($WEEKDAY -le 4 || $WEEKDAY -eq 6) ]]
		then
			# Normal 3pm chime on weekdays except Friday.
			kreuzglocke 110 delay
		elif [[ $HOUR -eq 15 && $WEEKDAY -le 5 ]]
		then
			# Special 3pm chime on Friday.
			dominika 100 delay
		elif [[ $HOUR -eq 18 && ($DECDATE -ge 929 || $DECDATE -lt 423) ]]
		then
			# Earlier evening chime at 6pm from September 29th on.
			betglocke 140 delay
		elif [[ $HOUR -eq 20 && $DECDATE -ge 423 && $DECDATE -lt 929 ]]
		then
			# Later evening chime at 8pm from April 23rd on.
			betglocke 140 delay
		fi
	else
		# If it's not a full hour, just end the quarter strokes.
		quarterend
	fi
fi
