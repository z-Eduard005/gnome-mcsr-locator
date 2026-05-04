#!/bin/bash
DESKTOP_ENTRY_PATH="$HOME/.local/share/applications"
START_SCRIPT="$(pwd)/start.sh"
CB_SCRIPT="$(pwd)/get-last-cb-item.sh"

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }
info() { printf "\033[1;34m%s\033[0m" "$1"; }
throw_err() { echo "$(err "$1")"; exit 1; }

install_nodejs() {
  if command -v dnf &>/dev/null; then
    sudo dnf install -y nodejs
  elif command -v apt &>/dev/null; then
    sudo apt install -y nodejs
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm nodejs
  elif command -v zypper &>/dev/null; then
    sudo zypper install -y nodejs
  else
    throw_err "No supported package manager found. Please install nodejs manually."
  fi
}

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

if [ "$EUID" -eq 0 ]; then
  echo "$(err 'Do not run this script with "sudo"!')" >&2
  exit 1
fi

[ -z "$1" ] || [ -z "$2" ] && { echo "$(err "Usage: $0 <desktop_entry_name> <minecraft_filename (without '.desktop')>")"; exit 1; }

install_nodejs || throw_err "Failed to install nodejs"

echo "$(info "Shortcut not found. Installing...")"
create_gnome_shortcut "get-last-cb-item" "Get Last Clipboard Item" "$CB_SCRIPT" "Insert"

echo "$(info "Setting up start script...")"
sed -i "\$ s/\s*[^[:space:]]\+\$/ $2/" "$START_SCRIPT"

echo "$(info "Updating desktop entry...")"
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

echo "$(success "MCSR locator successfully installed")"
