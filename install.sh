#!/bin/sh
#     _
#  __| | __ _ _ __   ___ ___ 
# / _` |/ _` | '_ \ / __/ _ \
#| (_| | (_| | | | | (_|  __/
# \__,_|\__,_|_| |_|\___\___| by Durryx
checkinternet(){
        # check if connection can be establiched	
	wget -q --spider 'https://google.com'
	if [ $? -ne 0 ]; then
		whiptail --title "No internet connection" --ok-button "exit" \
		--msgbox "Internet connection is needed in order to install all packages, refer to your distro's documentation to access the network" 20 40 3>&1 1>&2 2>&3
		exit 1
	else
		printf "Internet connection available\n"
	fi
	}
checkroot(){
	# check if user ID is 0 (root{
	if [[ $(id -u) != 0 ]];then
		whiptail --title "Run as root" --ok-button "next"\
		--msgbox "Please run the script as root, the current user is $(whoami)" 20 40 3>&1 1>&2 2>&3
		exit 1
	else
		printf "Running the script as root\n"
	fi
	}
selectuser(){ select x in "${userlist[@]}"; do echo "$x"; break; done; }
checkuser(){
	# get list of users from 1000 to 6000, normal users
	local userstring=$(getent passwd {1000..6000} | cut -d: -f1)
	# check if at least one normal user exists
	[ -z "$userstring" ] && printf "no normal user detected, exiting\n" && exit 1
	userlist=( $userstring )
	while true; do
		clear
		# setting prompt string
		PS3="Choose user, enter option's number: "
		echo -e "\n\t\tAvailable users\n"
		user=$(selectuser)
		[[ ! -z "$user" ]] && break
	done
	home=/home/$user
	}
syntaxerr(){ printf "\e[1;31m Invalid syntax of config.yml \e[1;31m"; exit 1; }
nofile(){ printf "\e[1;31m File or directory indicated in config.yml not found \e[1;31m"; exit 1; }
noconfig(){ printf "\e[1;31m No config.yml file found \e[1;31m"; exit 1; } 
checkconfig(){
	# check if config.yml exists
	[[ ! -f config.yml ]] && noconfig  
	pacman -S --noconfirm yamllint yq
	# check if YAML syntax file is correct
	yamllint config.yml
	[[ $? != 0 ]] && syntaxerr
	# if you have put an odd number of paths in the files field then a paste path misses
	local var=$(yq '.files | .[]' config.yml | wc -l)
	[[ $((var % 2 )) == 0 ]] || syntaxerr	
	while IFS= read -r string; do
		 # check if file or directory indicated exists
		 [[ ! -e $string ]] && nofile
	done <<< "$(yq '.files | .[]' config.yml | sed -n 'p;n' | tr -d '"')"
	}
message(){
	whiptail --title "Welcome" --ok-button "next" --msgbox "Welcome to Durry's auto-ricing script!\\n\\nYour going to install a fully \
		configured i3-wm desktop onto your preferred Linux distro. Let's go!" 20 40 3>&1 1>&2 2>&3
	clear
	checkinternet
	checkroot
	checkuser
	checkconfig
	}

installpkg(){
	clear
	# set lists of the various packages to be installed
	local PACMAN=$(yq '.pacman' config.yml | tr -d '[],"')
	local YAY=$(yq '.yay' config.yml | tr -d '[],"')
	local PIP=$(yq '.pip' config.yml | tr -d '[],"')
	pacman -Sy --noconfirm --needed $PACMAN
	# install yay AUR helper
	mkdir /opt/yay-git/
	git clone "https://aur.archlinux.org/yay-git.git" /opt/yay-git/
	chown -R $user:$user /opt/yay-git
	cd /opt/yay-git/; sudo -u $user "makepkg" -si --noconfirm; cd -
	sudo -u $user "yay" -S --noconfirm $YAY
	pip install $PIP
	}
setdotfiles(){
	# create basic folders
	mkdir $home/Pictures $home/.local/share/konsole $home/Documents $home/Music $home/projects $home/Downloads
	# copy configuration files	
	for (( c=1; c<$(yq '.files | .[]' config.yml | wc -l); c=$((c+2)) )); do
		COPY=$(yq '.files | .[]' config.yml | sed -n "$c{p;q}" | sed "s|\"||g;s|~|$home|g")
		PASTE=$(yq '.files | .[]' config.yml | sed -n "$((c+1)){p;q}" | sed "s|\"||g;s|~|$home|g")
		cp -rf "$COPY" "$PASTE"
	done	
	chmod -R +xX "$home/.config/i3/scripts"*
	export PATH=$PATH:$home/scripts
	# enable icons for ranger
	git clone "https://github.com/alexanderjeurissen/ranger_devicons" $home/.config/ranger/plugins/ranger_devicons
	echo "default_linemode devicons" >> $home/.config/ranger/rc.conf
	chmod -R u+rw $home
	chmod +x $home/scripts
	# setting QT theme
	echo "export QT_STYLE_OVERRIDE=kvantum" >> $home/.profile
	# setting icons theme
	gsettings set org.gnome.desktop.interface icon-theme 'Tela'
	chown -R $user $home
	}
disablebeep(){
	# disable loud beep sound
	rmmod pcspkr
	echo "blacklist pcspkr" | tee /etc/modprobe.d/nobeep.conf
	}
fishshell(){
	# setting fish as default shell
	sudo -u "$user" chsh -s /usr/bin/fish
	echo /usr/bin/fish | tee -a /etc/shells
	fish -c "set -U fish_user_paths $home/scripts"
	}
taptoclick(){
	# enabling tap-to-click, it may not work for your touchpad
	[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
	# Enable left mouse button by tapping
	Option "Tapping" "on"
	EndSection' > /etc/X11/xorg.conf.d/40-libinput.conf	
	}
docs(){
        # generating documentation from latex file	
	pdflatex -interaction nonstopmode -file-line-error -output-directory=.. dance-doc.tex
	# removes garbage outputs	
	rm -f ../dance-doc.aux ../dance-doc.log ../dance-doc.out
	} 
choose(){
	# enable all threads, caching with ccache for makepkg
	sed -i "s-/-j2/j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/;s|!ccache|ccache|" /etc/makepkg.conf
        cp addons.sh $home	
	whiptail --yesno "Install everything? (recommended)" 10 100 3>&1 1>&2 2>&3
	if [[ $? == 0 ]]; then
		local choice="installpkg fishshell iconflameshot setdotfiles taptoclick docs nopowerkey"	
	else
		local choice=$(whiptail --title "Choose what to install:" --checklist "Options" 10 60 5 "installpkg" "install al packages" on "setdotfiles" "customization" on \
			"fishshell" "use fish shell as default" off "nopowerkey" "disable powerkey" off "taptoclick" "enable tap to click" off \ 
			"iconflameshot" "no tray icon for flameshot" on "docs" "generate PDF document" on 3>&1 1>&2 2>&3)
	fi
	[[ .*"$choice".* =~ "installpkg" ]] && installpkg
	[[ .*"$choice".* =~ "fishshell" ]] && fishshell
	[[ .*"$choice".* =~ "iconflameshot" ]] && sudo -u "$user" flameshot config -t false
	[[ .*"$choice".* =~ "setdotfiles" ]] && setdotfiles
	[[ .*"$choice".* =~ "taptoclick" ]] && taptoclick
	[[ .*"$choice".* =~ "docs" ]] && docs
	timedatectl set-ntp 1
	[[ .*"$choice".* =~ "nopowerkey" ]] && sed -i 's/#HandlePowerKey=poweroff/HandlePowerKey=none/g' /etc/systemd/logind.conf
	disablebeep
	}
services(){
	# enable pulseaudio, lightdm as display manager, cups for printers
	systemctl enable lightdm
	systemctl enable cups
	killall pulseaudio; sudo -u $user pulseaudio --start
	}

message
choose
# patch dmenu to make it display emoji
sudo -u "$user" yay -S libxft-bgra-git
services
echo "exec --no-startup-id termite -e \"sh $home/addons.sh\"" >> $home/.config/i3/config
exiting=$(whiptail --title "Installation ended" --menu "Everything has been set up correctly.\\n-Durry" 15 50 4 \
	"1" "exit" "2" "reboot"	3>&1 1>&2 2>&3)
[[ $exiting == "2" ]] && reboot
