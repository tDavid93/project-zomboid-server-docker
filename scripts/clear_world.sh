#!/bin/bash
set -euo pipefail

SAVE_DIR="/home/bonefire/probe/new_pz/data/Saves/Multiplayer/servertest"
DB_FILE="/home/bonefire/probe/new_pz/data/db/servertest.db"

cat <<MSG
This will delete:
  - ${SAVE_DIR}
  - ${DB_FILE}
Type 'delete' to continue: 
MSG

read -r confirm
if [ "${confirm}" != "delete" ]; then
  echo "Aborted."
  exit 1
fi

rm -rf "${SAVE_DIR}"
rm -f "${DB_FILE}"

echo "Deleted save and db for servertest."
