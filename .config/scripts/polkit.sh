#/usr/libexec/polkit-gnome-authentication-agent-1 & 

fedora_polkit=/usr/libexec/polkit-gnome-authentication-agent-1

if test -f $fedora_polkit;then
  $fedora_polkit &
else
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
fi
