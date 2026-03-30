# Minecraft Stronghold Locator Fedora (GNOME/Wayland)

Simple script designed for measuring eye angles. It parses `F3+C` coordinates from a clipboard, calculates stronghold intersections using triangulation, and sends persistent, critical D-Bus notifications that bypass "Do Not Disturb" mode.

## Install Script
```bash
git clone https://github.com/z-Eduard005/fedora-mcsr-locator && cd fedora-mcsr-locator && ./install.sh
```

## Description
1. Creates a native GNOME shortcut (`Insert` key by default) for getting coordinates from clipboard history
2. Creates a Desktop Entry for launching Minecraft with the program in the default terminal

## Usage
1. Throw first eye -> `F3+C` -> `Insert`<br> *You will get notiffication for 5 sec when eye measured correctly*
2. Move -> Throw second eye -> `F3+C` -> `Insert`<br> *You will get error or persistent success notiffication with OW/Nether coords*
3. To continue measuring third eye or start over after success, just make another `F3+C` -> `Insert` step
