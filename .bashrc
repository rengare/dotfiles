# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

alias s="startx"
alias f="fish"

export PATH=$PATH:/home/ren/.local/bin
export PATH=$PATH:/home/ren/.local/podman/bin
export PATH=$PATH:/home/ren/.nix-profile/bin

#SSH_AGENT_PID DEFAULT=
#SSH_AUTH_SOCK	DEFAULT="${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"

export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"
source /home/ren/.config/broot/launcher/bash/br

export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
. "$HOME/.cargo/env"


# Load Angular CLI autocompletion.
source <(ng completion script)
