#!/bin/bash

# Function to recursively search for a folder name
search_folder() {
    local search_dir="$1"
    counter=1

    for item in "$search_dir"/*; do

        echo "Searching for maps: ($counter/$(ls -1 "$search_dir" | wc -l))"

        # Check if the given directory exists
        if [ -d "$search_dir" ]; then                
        # Check if there is a "maps" folder within the "mods" directory
        if [ -d "$item/mods" ]; then
            for mod_folder in "$item/mods"/*; do
                # Build list of possible map roots for B42 workshop mods.
                map_roots=()
                if [ -d "$mod_folder/media/maps" ]; then
                    map_roots+=("$mod_folder/media/maps")
                fi
                if [ -d "$mod_folder/common/media/maps" ]; then
                    map_roots+=("$mod_folder/common/media/maps")
                fi
                if [ -d "$mod_folder/42/media/maps" ]; then
                    map_roots+=("$mod_folder/42/media/maps")
                fi

                if [ "${#map_roots[@]}" -gt 0 ]; then

                    # Copy maps to map folder
                    map_dir=("${HOMEDIR}/pz-dedicated/media/maps")

                    for map_root in "${map_roots[@]}"; do
                        for source_dir in "$map_root"/*; do
                            dir_name=$(basename "$source_dir")
                            if [ ! -d "$map_dir/$dir_name" ]; then
                                echo "Found map(s). Copying..."
                                cp -r "$map_root"/* "${HOMEDIR}/pz-dedicated/media/maps"
                                echo "Successfully copied!"
                                break
                            fi
                        done
                    done

                    # Adds map names to a semicolon separated list and outputs it.
                    map_list=""
                    for map_root in "${map_roots[@]}"; do
                        for dir in "$map_root"/*/; do
                            if [ -d "$dir" ]; then
                                dir_name=$(basename "$dir")
                                map_list+="$dir_name;"
                            fi
                        done
                    done
                    # Exports to .txt file to add to .ini file in entry.sh
                    echo -n "$map_list" >> "${HOMEDIR}/maps.txt"
                fi
            done
        fi
        fi
        ((counter++))
    done
}

parent_folder="$1"

if [ ! -d "$parent_folder" ]; then
    exit 1
fi

# Call the search_folder function with the provided arguments
search_folder "$parent_folder"
