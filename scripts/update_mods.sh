#!/bin/bash
set -euo pipefail

# Script to update server config with all local mods.
SERVERNAME="${SERVERNAME:-servertest}"
ZOMBOID_DIR="${ZOMBOID_DIR:-/home/steam/Zomboid}"
SERVER_INI="${ZOMBOID_DIR}/Server/${SERVERNAME}.ini"
MODS_DIR="${ZOMBOID_DIR}/mods"

echo "*** INFO: Scanning for local mods in ${MODS_DIR} ***"

MOD_LIST=""
if [ -d "${MODS_DIR}" ]; then
  for mod_dir in "${MODS_DIR}"/*/; do
    if [ -d "${mod_dir}" ]; then
      mod_name="$(basename "${mod_dir}")"
      echo "*** INFO: Found mod: ${mod_name} ***"
      if [ -z "${MOD_LIST}" ]; then
        MOD_LIST="${mod_name}"
      else
        MOD_LIST="${MOD_LIST};${mod_name}"
      fi
    fi
  done
fi

echo "*** INFO: Mod list: ${MOD_LIST} ***"

if [ -f "${SERVER_INI}" ]; then
  echo "*** INFO: Updating server configuration: ${SERVER_INI} ***"
  sed -i "s/^Mods=.*/Mods=${MOD_LIST}/" "${SERVER_INI}"
  echo "*** INFO: Server configuration updated ***"
else
  echo "*** ERROR: Server configuration file not found: ${SERVER_INI} ***"
  exit 1
fi
