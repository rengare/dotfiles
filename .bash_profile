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


if [ -e /home/ren/.nix-profile/etc/profile.d/nix.sh ]; then . /home/ren/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
