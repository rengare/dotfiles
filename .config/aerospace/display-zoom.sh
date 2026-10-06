#!/bin/sh
# $mod+Alt+m / $mod+Alt+n: sway-zoom in / out. macOS has no fractional scale,
# so step through the main display's HiDPI ("scaling:on") modes instead —
# a smaller logical resolution is a bigger UI.
# usage: display-zoom.sh in|out

list=$(displayplacer list) || exit 1

# the main display's block: from its "Persistent screen id" to the next one
block=$(printf '%s\n' "$list" | awk '
    /^Persistent screen id:/ { if (main) exit; buf = "" }
    { buf = buf $0 "\n" }
    /main display/ { main = 1 }
    END { if (main) printf "%s", buf }')
id=$(printf '%s\n' "$block" | awk '/^Persistent screen id:/ { print $4 }')
current=$(printf '%s\n' "$block" | awk '/^Resolution:/ { print $2 }')
[ -n "$id" ] && [ -n "$current" ] || exit 1

# HiDPI modes at least 1024 wide, widest (smallest UI) first
modes=$(printf '%s\n' "$block" | awk '/scaling:on/ { sub("res:", "", $3); print $3 }' \
    | awk -Fx '$1 >= 1024' | sort -t x -k1,1nr -u)

case "$1" in
    in)  next=$(printf '%s\n' "$modes" | awk -v c="$current" 'found { print; exit } $0 == c { found = 1 }') ;;
    out) next=$(printf '%s\n' "$modes" | awk -v c="$current" '$0 == c { print prev; exit } { prev = $0 }') ;;
    *)   echo "usage: $0 in|out" >&2; exit 2 ;;
esac

# already at the end of the range
[ -n "$next" ] || exit 0
displayplacer "id:$id res:$next scaling:on"
