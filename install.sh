#!/bin/bash
DESKTOP_ENTRY_PATH="$HOME/.local/share/applications"
START_SCRIPT="$(pwd)/start.sh"
CB_SCRIPT="$(pwd)/get-last-cb-item.sh"

success() { echo "$(printf '\033[1;32m%s\033[0m' "$*")"; }
err() { echo "$(printf '\033[1;31m%s\033[0m' "$*")"; }

create_gnome_shortcut() {
  local id="$1" name="$2" command="$3" binding="$4"
  local schema="org.gnome.settings-daemon.plugins.media-keys"
  local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${id}/"

  local existing
  existing=$(gsettings get "$schema" custom-keybindings)

  if echo "$existing" | grep -q "'$path'"; then
    local updated="$existing"
  else
    local updated=$(echo "$existing" | sed "s|]|, '${path}']|" | sed "s|\[, |[|")
  fi

  gsettings set "$schema" custom-keybindings "$updated"
  gsettings set "${schema}.custom-keybinding:${path}" name "$name"
  gsettings set "${schema}.custom-keybinding:${path}" command "$command"
  gsettings set "${schema}.custom-keybinding:${path}" binding "$binding"
}

[ -z "$1" ] || [ -z "$2" ] && { err "Usage: $0 <desktop_entry_name> <minecraft_filename (without '.desktop')>"; exit 1; }

SHORTCUT_EXISTS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | grep "get-last-cb-item")
if [ -z "$SHORTCUT_EXISTS" ]; then
  echo "Shortcut not found. Installing..."
  create_gnome_shortcut "custom-get-last-cb-item" "get-last-cb-item" "$CB_SCRIPT" "Insert"
fi

echo "Setting up start script..."
sed -i "\$ s/\s*[^[:space:]]\+\$/ $2/" "$START_SCRIPT"

echo "Updating desktop entry..."
cat > "$DESKTOP_ENTRY_PATH/$1.desktop" <<EOF
[Desktop Entry]
Name=$1
Exec=/bin/bash -lc "$START_SCRIPT"
Type=Application
Terminal=false
Icon=$(sed -n 's/^Icon=//p' "$DESKTOP_ENTRY_PATH/$2.desktop")
Categories=Application;
EOF
update-desktop-database "$DESKTOP_ENTRY_PATH"

success "All done"
