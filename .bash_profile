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
  else
      exec sw 
  fi
fi

