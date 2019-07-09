#!/bin/bash
#
# PowerStatus10k segment.
# This segment displays the current battery status.
# The segment differ between charging and discharging.
# The battery capacity is classified to display different icons representing the current
# capacity level.
# This is the smarter version compared to the default segment, because it does
# subscribe to battery changes instead of using an update interval.

[[ -n "$XDG_RUNTIME_DIR" ]] && FIFO_PATH="$XDG_RUNTIME_DIR" || FIFO_PATH=/tmp
FIFO_PATH+=/powerstatus10k/fifos/smartbattery

# Implement the interface function for the initial subscription state.
#
function initState_smartbattery() {
  [[ ! -d "$(dirname "$FIFO_PATH")" ]] && mkdir -p "$(dirname "$FIFO_PATH")"

  while inotifywait "$SMARTBATTERY_PATH_CHARGE" "$SMARTBATTERY_PATH_CAPACITY" &>/dev/null; do
    # Do this here to avoid problems on a deleted FIFO during runtime.
    [[ ! -e "$FIFO_PATH" ]] && mkfifo "$FIFO_PATH"
    printf 1 >"$FIFO_PATH"
  done &

  format_smartbattery
}

# Implement the interface function to format the current state of the subscription.
# This function does not care about any input, but just get triggered on
# updates.
#
function format_smartbattery() {
  # Get the current capacity.
  capacity=0

  # Read the capacity file if available.
  if [[ -f "$SMARTBATTERY_PATH_CAPACITY" ]]; then
    capacity=$(cat "${SMARTBATTERY_PATH_CAPACITY}")
  fi

  # Per default the battery is not charging.
  charging=0

  if [[ -f "$SMARTBATTERY_PATH_CHARGE" ]]; then
    charging=$(cat "${SMARTBATTERY_PATH_CHARGE}") # Get the additional icon.
  fi

  # Differ the icon list if charging.
  icon_list=("${SMARTBATTERY_ICONS_DISCHARGING[@]}") # Per default use the discharging list.

  if [[ $charging -eq 1 ]]; then
    icon_list=("${SMARTBATTERY_ICONS_CHARGING[@]}")
  fi

  # Get the icon based on the current capacity.
  icon="${icon_list[0]}" # Use full battery per default.

  for ((i = 0; i < ${#SMARTBATTERY_THRESHOLDS[@]}; i++)); do
    threshold=${SMARTBATTERY_THRESHOLDS[i]}

    # Check if the capacity is higher than the threshold.
    if [[ $capacity -ge $threshold ]]; then
      icon="${icon_list[i]}"
      break
    fi
  done

  # Set the color for the critical or full state.
  local color

  if [[ ! "$charging" -eq 1 ]] && [[ "$capacity" -le $SMARTBATTERY_CRITICAL_THRESHOLD ]]; then
    color="%{F${SMARTBATTERY_CRITICAL_COLOR}}"

  elif [[ $charging -eq 1 ]] && [[ "$capacity" -ge "$SMARTBATTERY_FULL_THRESHOLD" ]]; then
    color="%{F${SMARTBATTERY_FULL_COLOR}}"
  fi

  # Build the status string.
  # shellcheck disable=SC2034
  STATE="${color}${icon} ${capacity}%"
}
