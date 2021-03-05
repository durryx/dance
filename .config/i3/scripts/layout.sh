current=$(xkb-switch)
opt1='us'
opt2='it'

if [[ $current == $opt1 ]]; then
	setxkbmap it
elif [[ $current == $opt2 ]]; then
	setxkbmap us
else
	printf '\e[31m%s\e[0m' "current keyboard layout not present in layout.sh"
fi

