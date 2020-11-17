#!/usr/bin/env bash

if test "$BASH" = "" || "$BASH" -uc "a=();true \"\${a[@]}\"" 2>/dev/null; then
    # Bash 4.4, Zsh
    set -euo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u.
    set -eo pipefail
fi
shopt -s nullglob globstar

app_name=${1:-}
direction=${2:-next}

function echo_help {
    echo "Usage: $0 window_class [direction]"
    echo "Focuses one of the opened windows with the passed window_class on the condition of i3wm being currently running."
    echo "If the window of such class is already focused, then another one will be focused, appropriate to the passed direction."
    echo " window_class is a Window Manager window class"
    echo " direction denotes which window should be focused; possible values are next or previous, next being the default."
    echo ""
    echo "Examples:"
    echo " $0 Firefox"
    echo " $0 Firefox previous"
    echo " $0 Code previous"
}

if [ "$app_name" = '-h' ] || [ "$app_name" = '--help' ]
then
    echo_help
    exit 0
fi

# Check if the app name was passed and if not show an error to the user
if [ -z "$app_name" ]
then
    echo "You need to pass an app name as the first param!"
    exit 1
fi

# Check if the direction is a valid argument
if [ "$direction" != 'next' ] && [ "$direction" != 'previous' ]
then
    echo "Invalid direction passed! Expected 'next' or 'previous'."
    exit 2
fi

# Check if i3-msg is installed also silencing all of the output
if ! command -v i3-msg >/dev/null
then
    echo "i3-msg is needed for this script to work!"
    exit 3
fi

# Check if jq is installed also silencing all of the output
if ! command -v jq >/dev/null
then
    echo "jq is needed for this script to work!"
    exit 3
fi

# Get all the opened windows
all_windows=$(i3-msg -t get_tree | jq ".nodes | map(.nodes[]) | map(.nodes[]) | map(recurse(.nodes[]))[] | select(.window_properties != null)")
# Get all of the windows that belong to the $app_name
app_windows=$(echo "$all_windows" | jq "select(.window_properties.class == \"$app_name\")")

# Check if any windows were found and exit if not.
if [ -z "$app_windows" ]
then
    echo "No windows for said app found"
    exit 4
fi

# From now on I drop the app_ prefix in the variable naming schema, since variables will refer to
# app windows only.
mapfile -t windows_ids < <(echo "$app_windows" | jq '.id')
windows_count=${#windows_ids[@]}
windows_count=$(((windows_count - 1)))

focused_window_id=$(echo "$app_windows" | jq "select(.focused == true) | .id")
if [ -n "$focused_window_id" ]
then
    # The app is already focused, so we need to focus its next/previous instance
    for focused_index in "${!windows_ids[@]}"
    do
        # Current ID is that of the focused window, just break to save the index and go on.
        if [ "$focused_window_id" = "${windows_ids[$focused_index]}" ]
        then
            break;
        fi
    done
else
    # The app is not focused yet, so we need to do some hackery! Since we do some calculations and
    # bounds checking below, -1 is appropriate here.
    # If the user wants the next window, then the first one is appropriate.
    # If they want a previous one, then the last one will be used.
    focused_index=-1
fi

if [ "$direction" = "next" ]
then
    new_focused_index=$(((focused_index + 1)))
else
    new_focused_index=$(((focused_index - 1)))
fi

if [ "$new_focused_index" -gt "$windows_count" ]
then
    # The calculated index is bigger than the windows count, so wrap around, wrap around my child!
    new_focused_index=0
elif [ "$new_focused_index" -lt 0 ]
then
    # Same as above, but this time wrap around backwards.
    new_focused_index=$windows_count
fi

i3-msg "[con_id=\"${windows_ids[$new_focused_index]}\"] focus"
