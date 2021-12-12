#!/bin/bash

set -e

read -p "Are you sure you want to reset all settings and data? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

APP_ID=com.github.avojak.iridium
GSETTINGS_ID=$APP_ID
GSETTINGS_PATH=$APP_ID

print_setting () {
    echo -e "  $1 = $(flatpak run --command=gsettings $GSETTINGS_ID get $GSETTINGS_PATH $1)"
}

set_setting () {
    flatpak run --command=gsettings $GSETTINGS_ID set $GSETTINGS_PATH $1 "$2"
    print_setting $1
}

clear_sqlite_table () {
    sqlite3 $DATABASE_PATH "DELETE FROM $1;"
    echo -e "  \u2714 Cleared $1"
}

echo
echo "Resetting GSettings..."

set_setting certificate-validation-policy "REJECT"
set_setting default-nickname ""
set_setting default-realname ""
set_setting suppress-connection-close-warnings false
set_setting remember-connections true
set_setting suppress-join-part-messages false
set_setting mute-mention-notifications false
set_setting font "Monospace Regular 9"
set_setting pos-x 360
set_setting pos-y 360
set_setting window-width 1000
set_setting window-height 600
set_setting last-server ""
set_setting last-channel ""

echo
echo "Resetting database..."

DATABASE_PATH=~/.var/app/$APP_ID/config/$APP_ID/iridium01.db

clear_sqlite_table servers
clear_sqlite_table channels
clear_sqlite_table server_identities
clear_sqlite_table sqlite_sequence

echo
echo -e "\033[1;32mDone\033[0m"
echo