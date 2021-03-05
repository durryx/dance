#!/bin/sh
time=0
passtime(){
	# pass time as a string --> 1d+1h+30min+20s
	for x in s min h d; do
		local add=$(echo $1 | grep $x | sed "s/$x//g" | bc)
		case $x in
			min) add=$((add*60));;
			h) add=$((add*3600));;
			d) add=$((add*86400));;
		esac
		time=$((time+add))
	done
	sleep $time
	notify-send --urgency critical "TIMER OFF"
	#mpv --no-audio-display file.wav
}

dmen(){
	local res=$(printf "30s\n10min\n1h:30min\n1d" | dmenu -i -p "Type how much time to wait:")
	[[ -z $res ]] && echo exit | dmenu -i -p "Invalid" && exit 1
	#[[ $res =~ "([0-9]+d:)?([0-9]+h:)?([0-9]+min:)?([0-9]+s)?" ]] || echo exit | dmenu -i -p 'Invalid' && exit 1
	res=$(echo $res | tr ':' '+')
	passtime $res
}
dmen
