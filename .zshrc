stty start undef
stty stop undef
setopt noflowcontrol
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.yarn/bin:$PATH
export PATH="$PATH:$HOME/workspace/flutter/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.npm-global/bin"

source /etc/profile.d/vte.sh

export ZSH="$HOME/.oh-my-zsh"

. ~/programs/z.sh

ZSH_THEME="arrow"

plugins=(
  git
  zsh-autosuggestions
  npm
  rust
)

source $ZSH/oh-my-zsh.sh
eval "$(fnm env)"

export EDITOR=lvim
export BROWSER=brave

alias x="startx"

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
alias vim="$HOME/.local/bin/lvim $1"
alias lvim="$HOME/.local/bin/lvim $1"
alias sedit="sudoedit $1"
alias debug="google-chrome --remote-debugging-port=9222"
alias h="history $1"

alias open="xdg-open $1"
alias quiet="sudo i8kfan 0 0"
alias mid="sudo i8kfan 1 1"
alias high="sudo i8kfan 2 2"

alias ls="exa $1"
alias l="exa -l $1"
#alias fd="fdfind"
alias space="du -sh $1"
alias freq='watch -n1 "grep \"^[c]pu MHz\" /proc/cpuinfo"'

alias tao="bluetoothctl connect 00:80:79:59:4A:E4"
alias taotao="bluetoothctl disconnect 00:80:79:59:4A:E4"
alias jab="bluetoothctl connect 50:1A:A5:36:87:00"
alias jabjab="bluetoothctl disconnect 50:1A:A5:36:87:00"

alias dotfs="/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"
alias ds="dotfs status"
alias da="dotfs add $1"
alias dc="dotfs commit"
alias dp="dotfs push"

alias cl="~/.cleanup"


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"