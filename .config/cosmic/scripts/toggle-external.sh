#!/usr/bin/env bash
# Toggle all non-builtin (external) outputs; leaves eDP-1 untouched.
outputs=$(cosmic-randr list | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^[^ ]+ \((enabled|disabled)\)$' | grep -v '^eDP-1 ')

[ -z "$outputs" ] && exit 0

if grep -q '(enabled)$' <<<"$outputs"; then
    grep '(enabled)$' <<<"$outputs" | awk '{print $1}' | while read -r output; do
        cosmic-randr disable "$output"
    done
else
    grep '(disabled)$' <<<"$outputs" | awk '{print $1}' | while read -r output; do
        cosmic-randr enable "$output"
    done
fi
