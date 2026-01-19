#!/bin/bash

# Script to automatically update server config with all local mods
SERVER_INI="/home/steam/Zomboid/Server/servertest.ini"
MODS_DIR="/home/steam/Zomboid/mods"

echo "*** INFO: Scanning for local mods ***"

# Find all directories in the mods folder (these are mod folders)
MOD_LIST=""
if [ -d "$MODS_DIR" ]; then
    for mod_dir in "$MODS_DIR"/*/; do
        if [ -d "$mod_dir" ]; then
            mod_name=$(basename "$mod_dir")
            echo "*** INFO: Found mod: $mod_name ***"
            if [ -z "$MOD_LIST" ]; then
                MOD_LIST="$mod_name"
            else
                MOD_LIST="$MOD_LIST;$mod_name"
            fi
        fi
    done
fi

echo "*** INFO: Mod list: $MOD_LIST ***"

# Update the server.ini file
if [ -f "$SERVER_INI" ]; then
    echo "*** INFO: Updating server configuration ***"
    sed -i "s/^Mods=.*/Mods=$MOD_LIST/" "$SERVER_INI"
    echo "*** INFO: Server configuration updated ***"
else
    echo "*** ERROR: Server configuration file not found ***"
fi