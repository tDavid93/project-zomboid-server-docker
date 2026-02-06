#!/bin/bash
set -euo pipefail

SERVERNAME="${SERVERNAME:-servertest}"
ZOMBOID_DIR="${ZOMBOID_DIR:-/home/steam/Zomboid}"
WORKSHOP_DIR="${WORKSHOP_DIR:-/home/steam/pz-dedicated/steamapps/workshop}"

BACKUP_DIR="${ZOMBOID_DIR}/backups"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
BACKUP_FILE="${BACKUP_DIR}/backup-${SERVERNAME}-${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

paths=(
  "${ZOMBOID_DIR}/Server"
  "${ZOMBOID_DIR}/Saves/Multiplayer"
  "${ZOMBOID_DIR}/db/${SERVERNAME}.db"
  "${ZOMBOID_DIR}/mods"
  "${ZOMBOID_DIR}/Workshop"
  "${WORKSHOP_DIR}"
)

include=()
for p in "${paths[@]}"; do
  if [ -e "${p}" ]; then
    include+=("${p}")
  else
    echo "*** WARN: Skipping missing path: ${p}"
  fi
done

if [ "${#include[@]}" -eq 0 ]; then
  echo "*** ERROR: No paths found to back up."
  exit 1
fi

tar -czf "${BACKUP_FILE}" "${include[@]}"
echo "*** INFO: Backup created: ${BACKUP_FILE}"
