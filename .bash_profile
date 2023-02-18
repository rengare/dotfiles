#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -e /home/ren/.nix-profile/etc/profile.d/nix.sh ]; then . /home/ren/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

if [ "$(tty)" = "/dev/tty1" ] ; then
    echo "tty1"
     exec sw 
     # exec it 
fi
