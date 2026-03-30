#!/bin/bash
ptyxis -- node "$(dirname "$0")/locator.js" &
gtk-launch LL
