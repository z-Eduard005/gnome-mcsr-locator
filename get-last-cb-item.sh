#!/bin/bash
wl-paste > "$(dirname "$0")/coords.txt"
wmctrl -a "Minecraft"
