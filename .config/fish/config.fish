export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
alias fzfpreview='fzf --preview "bat --style=numbers --color=always {} | head -500"'

export MANPAGER="nvim --clean +Man!"
export BAT_PAGER="less -R"

set -x HOSTNAME (echo $hostname)
# export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib"

export LIBRARY_PATH="$LIBRARY_PATH:/usr/lib:/usr/lib/x86_64-linux-gnu/"
export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig"

export CHROME_BIN=$HOME/.nix-profile/bin/chromium
export PATH="$PATH:/usr/bin:/bin:$HOME/.yarn/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.local/share/solana/install/active_release/bin"
export PATH="$PATH:$HOME/.local/podman/bin"
export PATH="$PATH:$HOME/.deno/bin"
export PATH="$PATH:$HOME/.nix-profile/bin"
export PATH="$PATH:/opt/homebrew/bin"
export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:/opt/rocm/bin"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
export PATH="$HOME/.emacs.d/bin:$PATH"

export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
export MANPAGER="nvim +Man!"

if [ -f /etc/wsl.conf ]
    alias ssh-add='ssh-add.exe'
    alias ssh='ssh-add.exe -l > /dev/null || ssh-add.exe && echo -e "\e[92mssh-key(s) are now available in your ssh-agent until you lock your windows machine! \n \e[0m" && ssh.exe'

end

switch (uname)
    case Darwin
        # Commands for macOS
        echo "Running on macOS"
        export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home
        export ANDROID_HOME=$HOME/Library/Android/sdk
        export ANDROID_SDK_ROOT=$ANDROID_HOME
        export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/21
        export NDK_HOME=$ANDROID_NDK_HOME
        export PATH="$PATH:$ANDROID_HOME/emulator"
        export PATH="$PATH:$ANDROID_HOME/platform-tools"
        export PATH="$PATH:$NDK_HOME"
        alias mcode="/Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron $1"
    case Linux
end

# export QT_QPA_PLATFORMTHEME="qt5ct"
export EDITOR=nvim
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
alias vim="nvim"
alias v="vim"
alias e="doom run -nw"
alias sedit="sudoedit $1"
alias debug="google-chrome --remote-debugging-port=9222"
alias h="history $1"
alias k="killall $1"
alias bru="brew update && brew upgrade && brew cleanup"
# alias clean="paru -Rns $(paru -Qdtq)"
alias arch="paru -Syu && flatpak update --user -y && bru"
alias fed="sudo dnf update -y && sudo dnf upgrade -y && flatpak --user update && bru"
alias distro="distrobox upgrade -a"
alias ubu="sudo nala update && sudo nala upgrade -y && flatpak update && bru"
alias zz="zellij"
alias y="yazi $1"

alias open="xdg-open $1"
alias quiet="sudo i8kfan 0 0"
alias mid="sudo i8kfan 1 1"
alias high="sudo i8kfan 2 2"

alias ls="exa $1"
alias l="exa -l $1"
alias space="du -ah . | sort -rh | head -10"
alias freq='watch -n1 "grep \"^[c]pu MHz\" /proc/cpuinfo"'
alias icat="kitty +kitten icat $1"

if type kitty >/dev/null 2>&1
    alias ssh="kitty +kitten ssh $1"
end

alias r="reset"
alias ldocker="lazydocker"
alias lpodman='DOCKER_HOST=unix:///run/user/1000/podman/podman.sock lazydocker'
alias nala="sudo nala $1"

if type "clip.exe" >/dev/null 2>&1
    alias xclip="clip.exe"
end

fish_vi_key_bindings

bind p fish_clipboard_paste
bind yy fish_clipboard_copy
bind Y fish_clipboard_copy

mise activate fish | source
