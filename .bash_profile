#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ "$(tty)" = "/dev/tty1" ] ; then
    echo "tty1"
     # exec sw 
     exec it 
fi
. "$HOME/.cargo/env"
