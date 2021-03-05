#!/bin/sh
percentage=$(df -hT | grep /$ | awk '{ print $6 }' 2>/dev/null)
if [[ $? == 0 ]]; then
	echo $percentage
else
	printf '\e[31m%s\e[0m' "invalid"
fi
# add click with ncdu
