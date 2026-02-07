#!/usr/bin/env bash
set -euo pipefail

SERVERNAME="${SERVERNAME:-servertest}"
ZOMBOID_DIR="${ZOMBOID_DIR:-/home/steam/Zomboid}"
SERVER_INI="${ZOMBOID_DIR}/Server/${SERVERNAME}.ini"
STEAMCMDDIR="${STEAMCMDDIR:-/home/steam/steamcmd}"
STEAMAPPDIR="${STEAMAPPDIR:-/home/steam/pz-dedicated}"
WORKSHOP_APPID="${WORKSHOP_APPID:-108600}"

if [ ! -f "${SERVER_INI}" ]; then
  echo "*** WARN: Server ini not found at ${SERVER_INI}; skipping workshop prefetch."
  exit 0
fi

items_raw="$(awk -F= '/^WorkshopItems=/{print $2}' "${SERVER_INI}")"
if [ -z "${items_raw}" ]; then
  echo "*** INFO: WorkshopItems is empty; nothing to prefetch."
  exit 0
fi

cmd_file="$(mktemp)"
{
  echo "force_install_dir ${STEAMAPPDIR}"
  echo "login anonymous"
  IFS=';' read -r -a items <<< "${items_raw}"
  for wid in "${items[@]}"; do
    if [ -n "${wid}" ]; then
      echo "workshop_download_item ${WORKSHOP_APPID} ${wid}"
    fi
  done
  echo "quit"
} > "${cmd_file}"

if ! "${STEAMCMDDIR}/steamcmd.sh" +runscript "${cmd_file}"; then
  echo "*** ERROR: Workshop prefetch failed."
  rm -f "${cmd_file}"
  exit 1
fi

rm -f "${cmd_file}"
echo "*** INFO: Workshop prefetch complete."
