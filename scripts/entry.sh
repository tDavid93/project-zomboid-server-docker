#!/bin/bash

cd ${STEAMAPPDIR}

#####################################
#                                   #
# Force an update if the env is set #
#                                   #
#####################################

if [ "${FORCESTEAMCLIENTSOUPDATE}" == "1" ]; then
  echo "FORCESTEAMCLIENTSOUPDATE variable is set, updating steamclient.so in Zomboid's server"
  cp "${STEAMCMDDIR}/linux64/steamclient.so" "${STEAMAPPDIR}/linux64/steamclient.so"
  cp "${STEAMCMDDIR}/linux32/steamclient.so" "${STEAMAPPDIR}/steamclient.so"
fi

if [ "${FORCEUPDATE}" == "1" ]; then
  echo "FORCEUPDATE variable is set, so the server will be updated right now"
  bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" +login anonymous +app_update "${STEAMAPPID}" -beta "${STEAMAPPBRANCH}" validate +quit
fi


######################################
#                                    #
# Process the arguments in variables #
#                                    #
######################################
ARGS=""

# Set the server memory. Units are accepted (1024m=1Gig, 2048m=2Gig, 4096m=4Gig): Example: 1024m
if [ -n "${MEMORY}" ]; then
  ARGS="${ARGS} -Xmx${MEMORY} -Xms${MEMORY}"
fi

# Option to perform a Soft Reset
if [ "${SOFTRESET}" == "1" ] || [ "${SOFTRESET,,}" == "true" ]; then
  ARGS="${ARGS} -Dsoftreset"
fi

# End of Java arguments
ARGS="${ARGS} -- "

# Runs a coop server instead of a dedicated server. Disables the default admin from being accessible.
# - Default: Disabled
if [ "${COOP}" == "1" ] || [ "${COOP,,}" == "true" ]; then
  ARGS="${ARGS} -coop"
fi

# Disables Steam integration on server.
# - Default: Enabled
if [ "${NOSTEAM}" == "1" ] || [ "${NOSTEAM,,}" == "true" ]; then
  ARGS="${ARGS} -nosteam"
fi

# Sets the path for the game data cache dir.
# - Default: ~/Zomboid
# - Example: /server/Zomboid/data
if [ -n "${CACHEDIR}" ]; then
  ARGS="${ARGS} -cachedir=${CACHEDIR}"
fi

# Option to control where mods are loaded from and the order. Any of the 3 keywords may be left out and may appear in any order.
# - Default: workshop,steam,mods
# - Example: mods,steam
if [ -n "${MODFOLDERS}" ]; then
  ARGS="${ARGS} -modfolders ${MODFOLDERS}"
fi

# Launches the game in debug mode.
# - Default: Disabled
if [ "${DEBUG}" == "1" ] || [ "${DEBUG,,}" == "true" ]; then
  ARGS="${ARGS} -debug"
fi

# Option to set the admin username. Current admins will not be changed.
if [ -n "${ADMINUSERNAME}" ]; then
  ARGS="${ARGS} -adminusername ${ADMINUSERNAME}"
fi

# Option to bypasses the enter-a-password prompt when creating a server.
# This option is mandatory the first startup or will be asked in console and startup will fail.
# Once is launched and data is created, then can be removed without problem.
# Is recommended to remove it, because the server logs the arguments in clear text, so Admin password will be sent to log in every startup.
if [ -n "${ADMINPASSWORD}" ]; then
  ARGS="${ARGS} -adminpassword ${ADMINPASSWORD}"
fi

# Server password (Doesn't work)
#if [ -n "${PASSWORD}" ]; then
#  ARGS="${ARGS} -password ${PASSWORD}"
#fi

# You can choose a different servername by using this option when starting the server.
if [ -n "${SERVERNAME}" ]; then
  ARGS="${ARGS} -servername ${SERVERNAME}"
else
  # If not servername is set, use the default name in the next step
  SERVERNAME="servertest"
fi

# If preset is set, then the config file is generated when it doesn't exists or SERVERPRESETREPLACE is set to True.
if [ -n "${SERVERPRESET}" ]; then
  # If preset file doesn't exists then show an error and exit
  if [ ! -f "${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" ]; then
    echo "*** ERROR: the preset ${SERVERPRESET} doesn't exists. Please fix the configuration before start the server ***"
    exit 1
  # If SandboxVars files doesn't exists or replace is true, copy the file
  elif [ ! -f "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua" ] || [ "${SERVERPRESETREPLACE,,}" == "true" ]; then
    echo "*** INFO: New server will be created using the preset ${SERVERPRESET} ***"
    echo "*** Copying preset file from \"${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua\" to \"${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua\" ***"
    mkdir -p "${HOMEDIR}/Zomboid/Server/"
    cp -nf "${STEAMAPPDIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    sed -i "1s/return.*/SandboxVars = \{/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # Remove carriage return
    dos2unix "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # I have seen that the file is created in execution mode (755). Change the file mode for security reasons.
    chmod 644 "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
  fi
fi

# Option to handle multiple network cards. Example: 127.0.0.1
if [ -n "${IP}" ]; then
  ARGS="${ARGS} ${IP} -ip ${IP}"
fi

# Set the DefaultPort for the server. Example: 16261
if [ -n "${PORT}" ]; then
  ARGS="${ARGS} -port ${PORT}"
fi

# Option to enable/disable VAC on Steam servers. On the server command-line use -steamvac true/false. In the server's INI file, use STEAMVAC=true/false.
if [ -n "${STEAMVAC}" ]; then
  ARGS="${ARGS} -steamvac ${STEAMVAC,,}"
fi

# Steam servers require two additional ports to function (I'm guessing they are both UDP ports, but you may need TCP as well).
# These are in addition to the DefaultPort= setting. These can be specified in two ways:
#  - In the server's INI file as SteamPort1= and SteamPort2=.
#  - Using STEAMPORT1 and STEAMPORT2 variables.
if [ -n "${STEAMPORT1}" ]; then
  ARGS="${ARGS} -steamport1 ${STEAMPORT1}"
fi
if [ -n "${STEAMPORT2}" ]; then
  ARGS="${ARGS} -steamport2 ${STEAMPORT2}"
fi

if [ -n "${PASSWORD}" ]; then
	sed -i "s/^Password=.*/Password=${PASSWORD}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${RCONPASSWORD}" ]; then
	sed -i "s/^RCONPassword=.*/RCONPassword=${RCONPASSWORD}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

# Shows the server on the in-game browser.
if [ "${PUBLIC}" == "1" ] || [ "${PUBLIC,,}" == "true" ]; then
  sed -i "s/^Public=.*/Public=true/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
elif [ "${PUBLIC}" == "0" ] || [ "${PUBLIC,,}" == "false" ]; then
  sed -i "s/^Public=.*/Public=false/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

# Set the display name for the server.
if [ -n "${DISPLAYNAME}" ]; then
  sed -i "s/^PublicName=.*/PublicName=${DISPLAYNAME}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${MOD_IDS}" ]; then
 	echo "*** INFO: Found Mods including ${MOD_IDS} ***"
	sed -i "s/Mods=.*/Mods=${MOD_IDS}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${WORKSHOP_IDS}" ]; then
 	echo "*** INFO: Found Workshop IDs including ${WORKSHOP_IDS} ***"
	sed -i "s/WorkshopItems=.*/WorkshopItems=${WORKSHOP_IDS}/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"
else
 	echo "*** INFO: Workshop IDs is empty, keeping existing configuration ***"
fi

# Fixes EOL in script file for good measure
sed -i 's/\r$//' /server/scripts/search_folder.sh
# Check 'search_folder.sh' script for details
if [ -e "${HOMEDIR}/pz-dedicated/steamapps/workshop/content/108600" ]; then

  map_list=""
  source /server/scripts/search_folder.sh "${HOMEDIR}/pz-dedicated/steamapps/workshop/content/108600"
  map_list=$(<"${HOMEDIR}/maps.txt")  
  rm "${HOMEDIR}/maps.txt"

  if [ -n "${map_list}" ]; then
    echo "*** INFO: Added maps including ${map_list} ***"
    sed -i "s/Map=.*/Map=${map_list}Muldraugh, KY/" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}.ini"

    # Checks which added maps have spawnpoints.lua files and adds them to the spawnregions file if they aren't already added
    IFS=";" read -ra strings <<< "$map_list"
    for string in "${strings[@]}"; do
        if ! grep -q "$string" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_spawnregions.lua"; then
          if [ -e "${HOMEDIR}/pz-dedicated/media/maps/$string/spawnpoints.lua" ]; then
            result="{ name = \"$string\", file = \"media/maps/$string/spawnpoints.lua\" },"
            sed -i "/function SpawnRegions()/,/return {/ {    /return {/ a\
            \\t\\t$result
            }" "${HOMEDIR}/Zomboid/Server/${SERVERNAME}_spawnregions.lua"
          fi
        fi
    done
  fi 
fi

# Fix to a bug in start-server.sh that causes to no preload a library:
# ERROR: ld.so: object 'libjsig.so' from LD_PRELOAD cannot be preloaded (cannot open shared object file): ignored.
export LD_LIBRARY_PATH="${STEAMAPPDIR}/jre64/lib:${LD_LIBRARY_PATH}"

# Optional workshop auto-update watcher.
AUTOUPDATE_MODS="${AUTOUPDATE_MODS:-0}"
if [ "${AUTOUPDATE_MODS}" = "1" ]; then
  echo "*** INFO: Workshop auto-update enabled (interval ${AUTOUPDATE_INTERVAL:-1800}s)."
fi

# Ensure Steam library folders exist for workshop downloads.
mkdir -p /home/steam/.steam
mkdir -p /home/steam/Steam/steamapps
mkdir -p /home/steam/pz-dedicated/steamapps/workshop/content/108600
mkdir -p /home/steam/pz-dedicated/steamapps/workshop/downloads
if [ ! -f /home/steam/Steam/steamapps/libraryfolders.vdf ]; then
  cat > /home/steam/Steam/steamapps/libraryfolders.vdf <<'VDF'
"libraryfolders"
{
  "0"
  {
    "path" "/home/steam/pz-dedicated"
    "label" ""
    "contentid" "1"
  }
}
VDF
fi

# Optional workshop prefetch before server start.
PREFETCH_WORKSHOP="${PREFETCH_WORKSHOP:-0}"
if [ "${PREFETCH_WORKSHOP}" = "1" ] && [ -x /server/scripts/prefetch_workshop.sh ]; then
  echo "*** INFO: Prefetching workshop mods before server start."
  if [ "$(id -u)" -eq 0 ]; then
    su - steam -c "/server/scripts/prefetch_workshop.sh" || exit 1
  else
    /server/scripts/prefetch_workshop.sh || exit 1
  fi
fi

# Fix common Linux case-sensitive path issues in workshop mods.
if [ -x /server/scripts/fix_case_sensitive_mod_paths.sh ]; then
  /server/scripts/fix_case_sensitive_mod_paths.sh
fi

# Seed defaultRoles when missing to avoid startup NPEs on some upgrades.
if command -v sqlite3 >/dev/null 2>&1; then
  DB_PATH="${HOMEDIR}/Zomboid/db/${SERVERNAME}.db"
  if [ -f "${DB_PATH}" ]; then
    ROLE_COUNT="$(sqlite3 "${DB_PATH}" "select count(*) from defaultRoles;" 2>/dev/null || echo "0")"
    if [ "${ROLE_COUNT}" = "0" ]; then
      echo "*** INFO: Seeding defaultRoles in ${DB_PATH} ***"
      sqlite3 "${DB_PATH}" <<'SQL'
INSERT INTO defaultRoles(name, role) SELECT 'defaultForBanned', id FROM role WHERE name='banned';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForNewUser', id FROM role WHERE name='user';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForUser', id FROM role WHERE name='user';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForPriorityUser', id FROM role WHERE name='priority';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForObserver', id FROM role WHERE name='observer';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForGM', id FROM role WHERE name='gm';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForOverseer', id FROM role WHERE name='gm';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForModerator', id FROM role WHERE name='moderator';
INSERT INTO defaultRoles(name, role) SELECT 'defaultForAdmin', id FROM role WHERE name='admin';
SQL
    fi
  fi
fi

## Fix the permissions in the data and workshop folders (only when running as root)
if [ "$(id -u)" -eq 0 ]; then
  chown -R 1000:1000 /home/steam/pz-dedicated/steamapps/workshop /home/steam/Zomboid
  # When binding a host folder with Docker to the container, the resulting folder has these permissions "d---" (i.e. NO `rwx`) 
  # which will cause runtime issues after launching the server.
  # Fix it by adding back `rwx` permissions for the file owner (steam user)
  chmod 755 /home/steam/Zomboid
  if [ "${AUTOUPDATE_MODS}" = "1" ]; then
    su - steam -c "/server/scripts/auto_update_mods.sh" &
    AUTOUPDATE_PID=$!
  fi
  su - steam -c "export LANG=${LANG} && export LD_LIBRARY_PATH=\"${STEAMAPPDIR}/jre64/lib:${LD_LIBRARY_PATH}\" && cd ${STEAMAPPDIR} && pwd && ./start-server.sh ${ARGS}" &
  SERVER_PID=$!
else
  export LANG=${LANG}
  export LD_LIBRARY_PATH="${STEAMAPPDIR}/jre64/lib:${LD_LIBRARY_PATH}"
  cd ${STEAMAPPDIR}
  if [ "${AUTOUPDATE_MODS}" = "1" ]; then
    /server/scripts/auto_update_mods.sh &
    AUTOUPDATE_PID=$!
  fi
  ./start-server.sh ${ARGS} &
  SERVER_PID=$!
fi

wait "${SERVER_PID}"
SERVER_EXIT=$?
if [ -n "${AUTOUPDATE_PID:-}" ]; then
  kill "${AUTOUPDATE_PID}" 2>/dev/null || true
fi
exit "${SERVER_EXIT}"
