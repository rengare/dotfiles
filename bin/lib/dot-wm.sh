#!/usr/bin/env bash
# The compositor primitives every dot-* script needs, one function per verb,
# sway on one branch and Hyprland on the other.
#
# Not on PATH and not in the dot-* symlink set (nix/linux/link.nix only links
# names starting "dot-" out of bin/) — sourced by path instead:
#   source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/dot-wm.sh"
#
# Every function that lists or matches windows emits the same five TSV
# columns regardless of compositor — id, pid, workspace, app, title — so a
# caller written against sway's `get_tree` shape does not need to know it is
# now looking at `hyprctl -j clients`. The id is opaque both ways (`con_id`
# under sway, a client `address` under Hyprland): callers round-trip it into
# wm_focus_window/wm_close_window without inspecting it.

wm_kind() {
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    echo hyprland
  else
    echo sway
  fi
}

# The compositor's own process name, as it appears in `comm` — used by
# dot-kill to find and protect the compositor and everything above it.
wm_process_name() {
  case "$(wm_kind)" in
    hyprland) echo Hyprland ;;
    *)        echo sway ;;
  esac
}

# id, pid, workspace, app, title — one row per window, heaviest logic (the
# sway side) unchanged from what dot-kill used to inline.
wm_windows_tsv() {
  case "$(wm_kind)" in
    hyprland)
      command -v hyprctl >/dev/null && command -v jq >/dev/null || return 0
      hyprctl -j clients 2>/dev/null | jq -r '
        .[] | [ .address, ((.pid // 0) | tostring),
                (.workspace.name // ((.workspace.id // 0) | tostring)),
                (.class // "?"), ((.title // "")[0:44]) ]
        | @tsv'
      ;;
    *)
      command -v swaymsg >/dev/null && command -v jq >/dev/null || return 0
      swaymsg -t get_tree 2>/dev/null | jq -r '
        .. | objects | select(.type == "workspace") | .name as $ws
        | recurse(.nodes[]?, .floating_nodes[]?)
        | select(.type == "con" or .type == "floating_con")
        | select(.app_id != null or .window_properties != null)
        | [ (.id | tostring), ((.pid // 0) | tostring), $ws,
            (.app_id // .window_properties.class // "?"),
            ((.name // "")[0:44]) ]
        | @tsv' 2>/dev/null
      ;;
  esac
}

# First window whose app_id/class or title contains $1, case-insensitively.
wm_find_window() {
  local pattern=$1
  case "$(wm_kind)" in
    hyprland)
      hyprctl -j clients 2>/dev/null | jq -r --arg p "$pattern" '
        .[] | select(((.class // "") | ascii_downcase | contains($p | ascii_downcase))
                  or ((.title // "") | ascii_downcase | contains($p | ascii_downcase)))
        | .address' | head -n1
      ;;
    *)
      swaymsg -t get_tree 2>/dev/null | jq -r --arg p "$pattern" '
        recurse(.nodes[]?, .floating_nodes[]?)
        | select(.type == "con" or .type == "floating_con")
        | select(((.app_id // "") | ascii_downcase | contains($p | ascii_downcase))
              or ((.window_properties.class // "") | ascii_downcase | contains($p | ascii_downcase))
              or ((.name // "") | ascii_downcase | contains($p | ascii_downcase)))
        | .id' | head -n1
      ;;
  esac
}

wm_focus_window() {
  local id=$1
  case "$(wm_kind)" in
    hyprland) hyprctl dispatch focuswindow "address:$id" >/dev/null 2>&1 ;;
    *)        swaymsg -q "[con_id=$id]" focus 2>/dev/null ;;
  esac
}

# A close *request*, not a signal — same distinction sway's `kill` command
# makes. Callers that need to force-close fall back to `kill -KILL` on the
# owning pid themselves; this only ever asks nicely.
wm_close_window() {
  local id=$1
  case "$(wm_kind)" in
    hyprland) hyprctl dispatch closewindow "address:$id" >/dev/null 2>&1 ;;
    *)        swaymsg -q "[con_id=$id]" kill 2>/dev/null ;;
  esac
}

# Every window whose app_id/class exactly matches $1, closed. Used only by
# dot-screensaver, where there is exactly one such window and no id to hand
# back from an earlier list call.
wm_close_by_class() {
  local pattern=$1
  case "$(wm_kind)" in
    hyprland) hyprctl dispatch closewindow "class:^$pattern\$" >/dev/null 2>&1 ;;
    *)        swaymsg -q "[app_id=^$pattern\$]" kill 2>/dev/null ;;
  esac
}

# How many windows currently have app_id/class exactly $1.
wm_count_by_class() {
  local pattern=$1
  case "$(wm_kind)" in
    hyprland)
      hyprctl -j clients 2>/dev/null \
        | jq --arg c "$pattern" '[.[] | select(.class == $c)] | length' 2>/dev/null
      ;;
    *)
      swaymsg -t get_tree 2>/dev/null | jq -r --arg a "$pattern" \
        "[recurse(.nodes[]?, .floating_nodes[]?) | select(.app_id == \$a)] | length" 2>/dev/null
      ;;
  esac
}

# The focused window's pid, or empty.
wm_focused_pid() {
  case "$(wm_kind)" in
    hyprland) hyprctl -j activewindow 2>/dev/null | jq -r '.pid // empty' ;;
    *)
      swaymsg -t get_tree 2>/dev/null | jq -r \
        'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true) | .pid // empty' \
        | head -n1
      ;;
  esac
}

# The focused window's geometry as grim/slurp's "X,Y WxH", or empty.
wm_focused_geometry() {
  case "$(wm_kind)" in
    hyprland)
      hyprctl -j activewindow 2>/dev/null | jq -r \
        'select(.address != null) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
      ;;
    *)
      swaymsg -t get_tree 2>/dev/null | jq -r \
        'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true)
         | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"' | head -n1
      ;;
  esac
}

# Run a command inside the session proper, not as a child of whatever is
# about to exit (rofi closing, a shell script returning) — the same reason
# dot-run and dot-keys hand commands to sway rather than running them here.
wm_exec() {
  local command=$1
  case "$(wm_kind)" in
    hyprland) hyprctl dispatch exec -- "$command" >/dev/null 2>&1 ;;
    *)        swaymsg -q -- exec "$command" 2>/dev/null ;;
  esac
}

wm_reload() {
  case "$(wm_kind)" in
    hyprland) hyprctl reload >/dev/null 2>&1 ;;
    *)        swaymsg reload >/dev/null 2>&1 ;;
  esac
}
