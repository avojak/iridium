#!/bin/bash

echo "installing dependencies for iridium"
if (whiptail --title "Choose distro" --yesno "What distro are you using?" 8 78 --no-button "Fedora Based" --yes-button "Ubuntu or Debian based"); then
  sudo apt install libsecret-1-dev libsqlite3-dev libgtksourceview-4-dev libsoup2.4-dev libhandy-1-dev && sudo apt install meson elementary-sdk
else
  sudo dnf install granite debhelper meson vala cmake gtk3-devel libgee-devel granite-devel libsecret-devel sqlite-devel gtksourceview4-devel libsoup-devel libhandy-devel
fi
