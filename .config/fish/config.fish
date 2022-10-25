set -x HOSTNAME (hostname)
export PATH="/usr/bin:/bin:$PATH:$HOME/.yarn/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.local/share/solana/install/active_release/bin"
export QT_QPA_PLATFORMTHEME="qt5ct"
export EDITOR=lvim
export BROWSER=brave
# export TERM=xterm
export TERM=kitty
export PNPM_HOME="$HOME/.npm-global/bin/"

alias x="startx"
alias f="flatpak $1"

alias s="git status"
alias b="git branch"
alias a="git add $1"
alias c="git commit $1"
alias push="git push $1"
alias p="git pull"
alias g="git log --all --decorate --oneline --graph"
alias cola="git-cola"
alias s.="nautilus ."
alias np="pnpm $1"
alias dev="tmux new -A -t dev"
alias t="dev"
alias lvim="$HOME/.local/bin/lvim $1"
alias vim="lvim"
alias v="vim"
alias sedit="sudoedit $1"
alias debug="google-chrome --remote-debugging-port=9222"
alias h="history $1"
alias k="killall $1"
alias deskon="curl 'http://192.168.8.232/win&T=1'"
alias deskoff="curl 'http://192.168.8.232/win&T=0'"
alias clean="paru -Qtdq | paru -Rns -"
alias update="paru -Syu && flatpak update -y && clean"
# alias cat="bat $1"

alias open="xdg-open $1"
alias quiet="sudo i8kfan 0 0"
alias mid="sudo i8kfan 1 1"
alias high="sudo i8kfan 2 2"

alias ls="exa $1"
alias l="exa -l $1"
#alias fd="fdfind"
alias space="du -sh $1"
alias freq='watch -n1 "grep \"^[c]pu MHz\" /proc/cpuinfo"'
alias icat="kitty +kitten icat $1"

alias dotfs="/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"
alias ds="dotfs status"
alias da="dotfs add $1"
alias dc="dotfs commit"
alias dp="dotfs push"

alias cl="~/.cleanup"

# bluetooth devices
alias gs1="bluetoothctl disconnect 14:C9:74:B9:66:42 && bluetoothctl connect 14:C9:74:B9:66:42"
alias gs2="bluetoothctl disconnect FF:E8:84:A0:A1:25 && bluetoothctl connect FF:E8:84:A0:A1:25"
alias lenovo="bluetoothctl disconnect B4:B6:B1:D9:72:06 && bluetoothctl connect B4:B6:B1:D9:72:06"
alias moode="bluetoothctl disconnect B8:27:EB:6A:88:A7 && bluetoothctl connect B8:27:EB:6A:88:A7"
alias jbl="bluetoothctl disconnect B8:F6:53:35:14:2A && bluetoothctl connect B8:F6:53:35:14:2A"

alias fm="export TERM='kitty' && broot"
alias fuzzpack="flatpak list | fzf | awk '{print \$3}' | xargs flatpak run"

fish_vi_key_bindings
bind p fish_clipboard_paste
bind yy fish_clipboard_copy
bind Y fish_clipboard_copy

# https://github.com/jethrokuan/fzf
