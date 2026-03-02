# User fish config - reorganized PATH block and small cleanups
# - PATH is built from an ordered list, deduplicated while preserving order.
# - Use `set -gx` to export environment variables (fish-style).
# - Prefer functions for command wrappers that accept arguments.

# ----- Basic tools & preferences ------------------------------------------------
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
alias fzfpreview 'fzf --preview "bat --style=numbers --color=always {} | head -500"'

set -gx MANPAGER 'nvim +Man!'
set -gx BAT_PAGER 'less -R'
set -gx EDITOR 'nvim'

# ----- Library / pkg config ----------------------------------------------------
# Reset and set LIBRARY_PATH explicitly
set -e LIBRARY_PATH
set -gx LIBRARY_PATH /usr/lib /usr/lib/x86_64-linux-gnu /usr/lib/aarch64-linux-gnu

# PKG_CONFIG_PATH is expected to be colon-separated by many tools, keep as string
set -gx PKG_CONFIG_PATH '/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/aarch64-linux-gnu/pkgconfig'

# ----- Other environment vars --------------------------------------------------
set -gx CHROME_BIN "$HOME/.nix-profile/bin/chromium"
set -gx PNPM_HOME "$HOME/.npm-global/bin/"

# ----- PATH: simple explicit export (user preference) --------------------------
# Edit this single line to reorder or add/remove directories. This will simply
# prepend your preferred paths in the order shown, then append the existing $PATH.
set -gx PATH \
    $HOME/.emacs.d/bin \
    $HOME/.local/share/bob/nvim-bin \
    $HOME/.local/share/flatpak/exports/bin \
    $HOME/.local/podman/bin \
    $HOME/.local/bin \
    $HOME/.npm-global/bin \
    $HOME/.yarn/bin \
    $HOME/.bun/bin \
    $HOME/.cargo/bin \
    $HOME/.deno/bin \
    $HOME/.local/share/solana/install/active_release/bin \
    $HOME/bin \
    $HOME/.nix-profile/bin \
    /home/linuxbrew/.linuxbrew/bin \
    /opt/homebrew/bin \
    /usr/local/bin \
    /opt/rocm/bin \
    /usr/bin \
    /bin \
    $PATH

# ----- Platform-specific tweaks ------------------------------------------------
if test -f /etc/wsl.conf
    alias ssh-add 'ssh-add.exe'
    function ssh
        # Ensure ssh-agent keys are loaded on WSL before invoking Windows ssh
        ssh-add.exe -l > /dev/null; or ssh-add.exe; and \
            echo -e "\e[92mssh-key(s) are now available in your ssh-agent until you lock your windows machine!\n\e[0m"
        ssh.exe $argv
    end
end

switch (uname)
    case Darwin
        # macOS specific
        set -gx JAVA_HOME '/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home'
        set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
        set -gx ANDROID_SDK_ROOT $ANDROID_HOME
        set -gx ANDROID_NDK_HOME "$ANDROID_HOME/ndk/21"
        set -gx NDK_HOME $ANDROID_NDK_HOME
        set -gx PATH $PATH $ANDROID_HOME/emulator $ANDROID_HOME/platform-tools $NDK_HOME
        function mcode
            /Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron $argv
        end
    case Linux
        # Linux-specific adjustments can be added here
end

# ----- Aliases and small helper functions -------------------------------------
# Use functions where we accept/forward arguments (more reliable in fish).
alias x 'startx'
function f --description 'flatpak wrapper forwarding arguments'
    flatpak $argv
end

alias his 'h | vim'
alias s 'git status'
alias b 'git branch'
function a --description 'git add wrapper'
    git add $argv
end
function c --description 'git commit wrapper'
    git commit $argv
end
function push --description 'git push wrapper with --force-with-lease by default'
    git push $argv --force-with-lease
end
alias p 'git pull'
alias g 'git log --all --decorate --oneline --graph'
alias cola 'git-cola'
alias lgit 'lazygit'
alias s. 'nautilus .'
function np
    pnpm $argv
end
alias dev 'tmux new -A -t dev'
alias t dev
alias vim 'nvim'
alias v vim
alias e 'doom run -nw'
function sedit
    sudoedit $argv
end
alias debug 'google-chrome --remote-debugging-port=9222'
function h
    history $argv
end
function k
    killall $argv
end
alias bru 'brew update && brew upgrade && brew cleanup'
alias arch 'paru -Syu && flatpak update --user -y && bru'
alias fed 'sudo dnf update -y && sudo dnf upgrade -y && flatpak --user update && bru'
alias distro 'distrobox upgrade -a'
alias ubu 'sudo nala update && sudo nala upgrade -y && flatpak update && bru'
alias zz 'zellij'
function y
    yazi $argv
end

function open
    xdg-open $argv
end

alias quiet 'sudo i8kfan 0 0'
alias mid 'sudo i8kfan 1 1'
alias high 'sudo i8kfan 2 2'
alias wiremix 'wiremix -v output'
alias audio 'wiremix'
alias blue 'bluetui'

alias ls 'exa $argv'
alias l 'exa -l $argv'
alias space 'du -ah . | sort -rh'
alias freq 'watch -n1 "grep \"^[c]pu MHz\" /proc/cpuinfo"'
function icat
    kitty +kitten icat $argv
end

if type kitty >/dev/null 2>&1
    function ssh
        kitty +kitten ssh $argv
    end
end

alias r 'reset'
alias ldocker 'lazydocker'
alias lpodman 'DOCKER_HOST=unix:///run/user/1000/podman/podman.sock lazydocker'
function nala
    sudo nala $argv
end

if type clip.exe >/dev/null 2>&1
    alias xclip 'clip.exe'
end

# ----- Key bindings -----------------------------------------------------------
fish_vi_key_bindings

bind p fish_clipboard_paste
bind yy fish_clipboard_copy
bind Y fish_clipboard_copy

# ----- Optional tool initializers ---------------------------------------------
# Only source/init if the tools exist to avoid noisy errors.
if type mise >/dev/null 2>&1
    mise activate fish | source
end

if type zoxide >/dev/null 2>&1
    zoxide init fish | source
end

# End of config.fish
