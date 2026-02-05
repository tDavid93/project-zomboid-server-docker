#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

SERVERNAME="${SERVERNAME:-servertest}"
BACKUP_DIR="${ROOT_DIR}/data/backups"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
BACKUP_FILE="${BACKUP_DIR}/backup-${SERVERNAME}-${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"
cd "${ROOT_DIR}"

paths=(
  "data/Server"
  "data/Saves/Multiplayer"
  "data/db/${SERVERNAME}.db"
  "data/mods"
  "data/Workshop"
  "workshop-mods"
  "local-mods"
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
