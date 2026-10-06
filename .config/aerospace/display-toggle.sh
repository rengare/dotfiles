#!/bin/sh
# $mod+Shift+o / $mod+Shift+p: toggle-edp.sh / toggle-external.sh from sway.
# usage: display-toggle.sh builtin|external

# one line per screen: <id> <builtin|external> <true|false>
screens=$(displayplacer list | awk '
    /^Persistent screen id:/ { id = $4 }
    /^Type:/ { kind = ($0 ~ /built in/) ? "builtin" : "external" }
    /^Enabled:/ { print id, kind, $2 }')

case "$1" in
    builtin|external) ;;
    *) echo "usage: $0 builtin|external" >&2; exit 2 ;;
esac

printf '%s\n' "$screens" | while read -r id kind enabled; do
    [ "$kind" = "$1" ] || continue
    if [ "$enabled" = true ]; then
        # unlike sway, a Mac with no screen left can't always turn it back on
        others=$(printf '%s\n' "$screens" | awk -v id="$id" '$1 != id && $3 == "true"' | wc -l)
        [ "$others" -gt 0 ] || { echo "$id is the only screen on, leaving it" >&2; continue; }
        displayplacer "id:$id enabled:false"
    else
        displayplacer "id:$id enabled:true"
    fi
done
