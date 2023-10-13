#
# ~/.bash_profile
#
DESKTOP_SESSION=i3
BROWSER=brave

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ "$(tty)" = "/dev/tty1" ] ; then
  if test -f ~/.i3 ; then
    startx
      # exec it 
  fi
  if test -f ~/.sway ; then
      exec sw 
  fi
fi

if [ -f $HOME/.nix-profile/etc/profile.d/nix.sh ];
then
    source $HOME/.nix-profile/etc/profile.d/nix.sh
fi
