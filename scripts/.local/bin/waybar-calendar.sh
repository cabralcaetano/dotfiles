#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"


CLASS="org.gnome.Calendar"

if /usr/bin/hyprctl clients -j | /usr/bin/jq -e --arg class "$CLASS" '.[] | select(.class == $class)' >/dev/null; then
  /usr/bin/hyprctl dispatch "hl.dsp.focus({ window = 'class:^(${CLASS})\$' })" >/dev/null
else
  /usr/bin/gnome-calendar >/dev/null 2>&1 &
fi
