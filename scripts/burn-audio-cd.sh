#!/usr/bin/env bash
# burn-audio-cd.sh — Convert and burn an album directory to audio CD
# Usage: burn-audio-cd.sh <path-to-album-directory> [cd-device] [--speed N]
# Dependencies: ffmpeg, normalize-audio, wodim

set -euo pipefail

TMPDIR="/tmp/burn-audio-cd-$$"
BURN_SPEED=16

usage() {
    echo "Usage: $(basename "$0") <album-directory> [cd-device] [--speed N]"
    echo ""
    echo "  album-directory   Path to directory containing audio files"
    echo "  cd-device         CD burner device (default: auto-detected)"
    echo "  --speed N         Burn speed (default: $BURN_SPEED)"
    echo ""
    echo "Supported input formats: any format supported by ffmpeg"
    echo "Required tools: ffmpeg, normalize-audio, wodim"
    exit 1
}

cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TMPDIR"
}

check_deps() {
    local missing=()
    for cmd in ffmpeg normalize-audio wodim soxi; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: missing required tools: ${missing[*]}"
        echo "Install with: sudo apt install ffmpeg normalize-audio wodim sox"
        exit 1
    fi
}

detect_device() {
    local dev
    dev=$(wodim --devices 2>/dev/null | awk -F"'" '/dev=/ {print $2}' | head -n1)
    if [[ -z "$dev" ]]; then
        echo "Error: no CD burner detected. Insert a disc and try again, or pass the device path as the second argument."
        exit 1
    fi
    echo "$dev"
}

# Returns the number of CD sectors a wav file will occupy including:
#   - padding to next sector boundary (1 sector = 588 samples @ 44100 Hz)
#   - 150-sector pre-gap wodim adds per track in TAO mode
wav_sectors() {
    local file="$1"
    local samples
    samples=$(soxi -s "$file")
    # ceil(samples / 588) + 150 pre-gap sectors
    awk "BEGIN { printf \"%d\", int(($samples / 588) + 0.9999) + 150 }"
}

sectors_to_mmss() {
    local s="$1"
    local total_sec=$(( s / 75 ))
    printf "%d:%02d" $(( total_sec / 60 )) $(( total_sec % 60 ))
}

# --- argument handling ---

[[ $# -lt 1 ]] && usage

ALBUM_DIR="${1%/}"
if [[ ! -d "$ALBUM_DIR" ]]; then
    echo "Error: '$ALBUM_DIR' is not a directory."
    exit 1
fi
shift

CD_DEV=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --speed)
            [[ -z "${2:-}" || ! "${2}" =~ ^[0-9]+$ ]] && { echo "Error: --speed requires a numeric value."; exit 1; }
            BURN_SPEED="$2"
            shift 2
            ;;
        --speed=*)
            val="${1#--speed=}"
            [[ ! "$val" =~ ^[0-9]+$ ]] && { echo "Error: --speed requires a numeric value."; exit 1; }
            BURN_SPEED="$val"
            shift
            ;;
        -*)
            echo "Error: unknown option '$1'."
            usage
            ;;
        *)
            if [[ -z "$CD_DEV" ]]; then
                CD_DEV="$1"
            else
                echo "Error: unexpected argument '$1'."
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "$CD_DEV" ]]; then
    echo "Auto-detecting CD burner..."
    CD_DEV=$(detect_device)
    echo "Found: $CD_DEV"
fi

# --- setup ---

check_deps
trap cleanup EXIT

mkdir -p "$TMPDIR"
echo "Working directory: $TMPDIR"

# --- step 1: copy files with spaces replaced by underscores ---

echo ""
echo "==> Copying and sanitising filenames..."
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    safe=$(echo "$filename" | tr ' ' '_')
    cp "$file" "$TMPDIR/$safe"
done < <(find "$ALBUM_DIR" -maxdepth 1 -type f \( \
    -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.flac" \
    -o -iname "*.aac" -o -iname "*.m4a" -o -iname "*.wav" \
    -o -iname "*.wma" -o -iname "*.opus" \) -print0 | sort -z)

file_count=$(ls -1 "$TMPDIR" | wc -l)
if [[ "$file_count" -eq 0 ]]; then
    echo "Error: no supported audio files found in '$ALBUM_DIR'."
    exit 1
fi
echo "Found $file_count audio file(s)."

# --- step 2: convert all files to wav ---

echo ""
echo "==> Converting all tracks to WAV..."
for file in "$TMPDIR"/*; do
    # skip files that are already the converted output
    [[ "$file" == *.wav ]] && continue
    outfile="${file}.wav"
    echo "  converting: $(basename "$file")"
    ffmpeg -loglevel warning -i "$file" -ar 44100 -ac 2 -acodec pcm_s16le "$outfile"
    rm "$file"
done

# --- step 3: normalise volume ---

echo ""
echo "==> Normalising audio levels..."
normalize-audio -m "$TMPDIR"/*.wav

# --- step 4: split tracks into disc-sized groups and burn ---

# Build sorted array of wav files
mapfile -t ALL_TRACKS < <(ls -1 "$TMPDIR"/*.wav | sort)
total_tracks=${#ALL_TRACKS[@]}
remaining=("${ALL_TRACKS[@]}")
disc_num=0
# 359846 sectors = 79:59 — standard 80-min CD-R lead-out position
CD_MAX_SECTORS=359846

while [[ ${#remaining[@]} -gt 0 ]]; do
    disc_num=$(( disc_num + 1 ))
    disc_tracks=()
    disc_sectors=0

    for track in "${remaining[@]}"; do
        secs=$(wav_sectors "$track")
        if (( disc_sectors + secs <= CD_MAX_SECTORS )); then
            disc_tracks+=("$track")
            disc_sectors=$(( disc_sectors + secs ))
        else
            # If this is the very first track on the disc it won't fit at all
            if [[ ${#disc_tracks[@]} -eq 0 ]]; then
                echo "Error: track '$(basename "$track")' alone exceeds CD capacity."
                exit 1
            fi
            break
        fi
    done

    disc_duration=$(sectors_to_mmss "$disc_sectors")
    remaining_after=()
    for track in "${remaining[@]}"; do
        already=0
        for dt in "${disc_tracks[@]}"; do
            [[ "$track" == "$dt" ]] && already=1 && break
        done
        [[ $already -eq 0 ]] && remaining_after+=("$track")
    done
    remaining=("${remaining_after[@]}")

    echo ""
    echo "==> Disc $disc_num — ${#disc_tracks[@]} track(s), ~${disc_duration} min"
    for t in "${disc_tracks[@]}"; do
        echo "    $(basename "$t")"
    done

    echo ""
    echo "    Insert blank CD-R disc $disc_num and press Enter to burn, or type 'q' to quit."
    read -r answer
    if [[ "${answer,,}" == "q" ]]; then
        echo "Aborted by user."
        exit 0
    fi

    sudo wodim -v -tao -eject "dev=$CD_DEV" speed="$BURN_SPEED" -audio -pad "${disc_tracks[@]}"

    echo ""
    echo "Disc $disc_num burned successfully."

    if [[ ${#remaining[@]} -gt 0 ]]; then
        echo ""
        echo "--- ${#remaining[@]} track(s) remaining ---"
        for t in "${remaining[@]}"; do
            echo "    $(basename "$t")"
        done
        echo ""
        echo "    Press Enter to continue to disc $(( disc_num + 1 )), or type 'q' to quit."
        read -r answer
        if [[ "${answer,,}" == "q" ]]; then
            echo "Stopped after disc $disc_num. Remaining tracks were not burned."
            exit 0
        fi
    fi
done

echo ""
echo "Done. All $total_tracks track(s) burned across $disc_num disc(s)."
