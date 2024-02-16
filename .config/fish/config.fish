set -x HOSTNAME (echo $hostname)
# export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib"
export CHROME_BIN=$HOME/.nix-profile/bin/chromium
export PATH="$PATH:/usr/bin:/bin:$HOME/.yarn/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.local/share/solana/install/active_release/bin"
export PATH="$PATH:$HOME/.local/podman/bin"
export PATH="$PATH:$HOME/.deno/bin"
export PATH="$PATH:$HOME/.nix-profile/bin"
export PATH="$PATH:/opt/homebrew/bin"
export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:/opt/rocm/bin"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"

if type brew >/dev/null 2>&1
    # export JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home
  
    export ANDROID_HOME=$HOME/Library/Android/sdk
    export ANDROID_SDK_ROOT=$ANDROID_HOME
    export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/21
    export NDK_HOME=$ANDROID_NDK_HOME

    export PATH="$PATH:$ANDROID_HOME/emulator"
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
    export PATH="$PATH:$NDK_HOME"

    #macos
    alias mcode="/Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron $1"
end

# export QT_QPA_PLATFORMTHEME="qt5ct"
export EDITOR=lvim
export BROWSER=brave
# export TERM=xterm
# export TERM=kitty
export PNPM_HOME="$HOME/.npm-global/bin/"

alias x="startx"
alias f="flatpak $1"
alias his="h | vim"

alias s="git status"
alias b="git branch"
alias a="git add $1"
alias c="git commit $1"
alias push="git push $1 --force-with-lease"
alias p="git pull"
alias g="git log --all --decorate --oneline --graph"
alias cola="git-cola"
alias lgit="lazygit"
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
alias arch="paru -Syu && flatpak update --user -y && clean"
alias fedora="sudo dnf update && sudo dnf upgrade -y && flatpak --user update"
alias ubuntu="sudo nala update && sudo nala upgrade -y && flatpak update"
alias nal="sudo nala install $1"
alias zel="zellij"
# alias cat="bat $1"

alias open="xdg-open $1"
alias quiet="sudo i8kfan 0 0"
alias mid="sudo i8kfan 1 1"
alias high="sudo i8kfan 2 2"

alias ls="exa $1"
alias l="exa -l $1"
#alias fd="fdfind"
alias space="du -ah . | sort -rh | head -10"
alias freq='watch -n1 "grep \"^[c]pu MHz\" /proc/cpuinfo"'
alias icat="kitty +kitten icat $1"
alias ssh="kitty +kitten ssh $1"
alias r="reset"

# bluetooth devices
alias gs1="bluetoothctl disconnect 14:C9:74:B9:66:42 && bluetoothctl connect 14:C9:74:B9:66:42"
alias gs2="bluetoothctl disconnect FF:E8:84:A0:A1:25 && bluetoothctl connect FF:E8:84:A0:A1:25"
alias lenovo="bluetoothctl disconnect B4:B6:B1:D9:72:06 && bluetoothctl connect B4:B6:B1:D9:72:06"
alias moode="bluetoothctl disconnect 04:7F:0E:08:68:71 && bluetoothctl connect 04:7F:0E:08:68:71"
alias jbl="bluetoothctl disconnect B8:F6:53:35:14:2A && bluetoothctl connect B8:F6:53:35:14:2A"
alias desk="bluetoothctl disconnect F4:4E:FD:72:A2:47 && bluetoothctl connect F4:4E:FD:72:A2:47"

alias fm="export TERM='wezterm' && broot"
alias fuzzpack="flatpak list | fzf | awk '{print \$3}' | xargs flatpak run"


fish_vi_key_bindings
bind p fish_clipboard_paste
bind yy fish_clipboard_copy
bind Y fish_clipboard_copy

fnm env | source
pyenv init - | source

# starship init fish | source

