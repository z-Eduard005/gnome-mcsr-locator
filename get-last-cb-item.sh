#!/bin/bash
wl-paste > "$(dirname "$0")/coords.txt"
[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] || wmctrl -a "Minecraft"
