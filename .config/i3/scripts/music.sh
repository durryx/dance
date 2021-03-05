pgrep yakuake >/dev/null
[[ $? == 1 ]] && yakuake &
pgrep cmus >/dev/null
[[ $? == 0 ]] && pkill cmus
session=$(qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.addSession)

qdbus org.kde.yakuake /yakuake/tabs org.kde.yakuake.setTabTitle $session 'music'

qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.runCommandInTerminal $session \
	"tmux new-session -d -s music-session 'cava'"

qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.runCommandInTerminal $session \
	"tmux rename-window 'dj set'"

qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.runCommandInTerminal $session \
	"tmux select-window -t music-session:0"

qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.runCommandInTerminal $session \
	"tmux split-window -h 'cmus'"

qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.runCommandInTerminal $session\
	"tmux -2 attach-session -t music-session"

sleep 0.2; yakuake	 
