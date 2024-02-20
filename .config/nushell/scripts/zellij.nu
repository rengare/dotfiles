# Zellij auto attach
$env.ZELLIJ_CONFIG_DIR = $"($env.HOME)/.config/zellij"
if not ("ZELLIJ" in $env) {
  zellij attach -c "main"
}

# Zellij fzf pickers
def zellija [] {
 let sessions = (zellij list-sessions)
 let fzfResult = ($sessions | (fzf --height 22% --border --prompt='Attach: ' --print-query))

 # get the query and fzf-selection:
 mut userQuery = ($fzfResult | lines | get -i 0 | default "")
 mut userSelection = ($fzfResult | lines | get -i 1 | default "")

 # user quit fzf with esc or ctrl-c
 if (($userQuery | is-empty) and ($userSelection | is-empty)) {
    return
 }

 if ($userSelection | str contains "(current)") {
   $userSelection = ($userSelection | str replace "(current)" "" | str trim)
 }

 mut sessionName = $userSelection

 # create new session with fzf query if -n is present or no current results are shown
 if (($userSelection | is-empty) or ($userQuery | str contains " -n")) {
   $userQuery = ($userQuery | str replace " -n" "")
   $sessionName = $userQuery
 }

 zellij attach -c $sessionName
}

def zellijk [] {
 let sessions = (zellij list-sessions)
 mut userSelection = ($sessions | (fzf --height 22% --border --prompt='Kill: ' --print-query) | lines | get -i 1 | default "" | str replace "(current)" "" | str trim)

 # user quit fzf with esc or ctrl-c, or no session was picked
 if (($userSelection| is-empty)) {
    return
 }

 zellij kill-session $userSelection
}
