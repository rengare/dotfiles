function zz --description 'zellij session manager: zz attach <name> attaches to / creates (with layout <name>) a named session'
    if test (count $argv) -ge 2; and test "$argv[1]" = attach
        set -l name $argv[2]

        # Can't create/switch sessions from inside another one (zellij won't nest).
        if set -q ZELLIJ
            if test "$ZELLIJ_SESSION_NAME" = "$name"
                echo "Already in session '$name'."
            else
                echo "Inside session '$ZELLIJ_SESSION_NAME'. Detach first (Ctrl o then d), then: zz attach $name"
            end
            return 1
        end

        # Outside zellij: attach to a live session, else create it with its layout.
        set -l line (zellij list-sessions --no-formatting 2>/dev/null | string match -r "^$name\b.*")
        if test -n "$line"; and not string match -q '*EXITED*' -- "$line"
            zellij attach $name
        else
            test -n "$line"; and zellij delete-session $name 2>/dev/null
            zellij --session $name --new-session-with-layout $name
        end
    else
        zellij $argv
    end
end
