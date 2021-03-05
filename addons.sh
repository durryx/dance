#!/bin/sh
#     _                      
#  __| | __ _ _ __   ___ ___ 
# / _` |/ _` | '_ \ / __/ _ \
#| (_| | (_| | | | | (_|  __/
# \__,_|\__,_|_| |_|\___\___| by Durryx
selectuser(){ select x in "${userlist[@]}"; do echo "$x"; break; done; }
checkuser(){
	local userstring=$(getent passwd {1000..6000} | cut -d: -f1)
	[ -z "$userstring" ] && printf "no normal user detected, exiting\n" && exit 1
	userlist=( $userstring )
	while true; do
		clear
		PS3="Choose user, enter option's number: "
		echo -e "\n\t\tAvailable users\n"
		export user=$(selectuser)
		[[ ! -z "$user" ]] && break
	done
	export home=/home/$user
	}
setupffmpeg(){
	pacman -Sy --noconfirm --needed cuda cuda-tools
	opt2=$(whiptail --title "Installing nvidia-sdk" --inputbox \
	"You need to manually download the SDK from https://developer.nvidia.com/nvidia-video-codec-sdk Then provide here the absolute path to the file:"\
	20 90 --cancel-button "skip nvidia-sdk installation" 3>&1 1>&2 2>&3)
	if [ $? -ne 1 ] && [ -f $opt2 ]; then
	# waring to file does not exist
	sudo -u "$user" yay -S --noconfirm nvidia-sdk
	cp $opt2 "/home/$user/.cache/yay/nvidia-sdk/" || echo "failed to copy file from $opt2 to nvdia-sdk"
	chown -R "$user" /home/$user/.cache/yay/nvidia-sdk/
	cd $home/.cache/yay/nvidia-sdk; sudo -u $user makepkg -si; cd -
	sudo modprobe nvidia_uvm
	fi
	export PATH=$PATH:/opt/cuda/bin
	sudo -u "$user" yay -S ffmpeg-full-git
	}
virtmanagersetup(){
	pacman -Sy --needed --noconfirm virt-manager virt-viewer qemu dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables
	sudo -u "$user" yay -S --needed --noconfirm libguestfs-git
	systemctl enable libvirtd.service
	systemctl start libvirtd.service
	sed -i '/unix_sock_group/c\unix_sock_group = "libvirt"' /etc/libvirt/libvirtd.conf
	sed -i '/unix_sock_rw_perms/c\unix_sock_rw_perms = "0770"' /etc/libvirt/libvirtd.conf
	usermod -a -G libvirt $user
	#newgrp libvirt
	systemctl restart libvirtd.service
}
ohmyfish(){
	pacman -Q | grep -q fish || printf "fish is not installed, installing\n" && pacman -Sy --noconfirm fish
	whiptail --title "oh-my-fish" --msgbox "exit from fish shell to return to the postinstallation script" 24 60 3>&1 1>&2 2>&3
	sudo -u "$user" sh -c "curl -L 'https://get.oh-my.fish' > install"
	chmod +x install
	sudo -u "$user" termite -e "fish install --path=~/.local/share/omf --config=~/.config/omf"
	rm install
	sudo -u $user fish -c "omf install aight"
	#sudo -u "$user" fish -c "omf install fishbone"
	#sed 's@pwd@pwd | sed "s|^HOME|~|"@g' /home/$user/.config/fish/functions/fish_prompt.fish
	#mv /home/$user/.local/share/omf/themes/fishbone/fish_greeting.fish /home/$user/.local/share/omf/themes/fishbone/fish_greeting.fish.bkp
}

if [[ $UID -ne 0 ]]; then
	sudo -p 'Restarting as root, enter password: ' sh $0 "$@"
	exit $?
fi
checkuser
options=$(whiptail --title "postinstall" --checklist "Choose what to install" 10 60 5 "ffmpeg-full" "install ffmpef-full" on "virt-manager" "install virt-manager" off "ohmyfish" "oh-my-fish with custom setup" off 3>&1 1>&2 2>&3)
[[ .*"$options".* =~ "ffmpeg-full" ]] && setupffmpeg
[[ .*"$options".* =~ "virt-manager" ]] && virtmanagersetup
[[ .*"$options".* =~ "ohmyfish" ]] && ohmyfish
whiptail --title "Bye bye" --msgbox "Everything has been set up. You can find the PDF documentation in ~/dance-doc.pdf" 20 40
sed -i -e "s|exec --no-startup-id termite -e \"sh $home/addons.sh\"||g" $home/.config/i3/config
