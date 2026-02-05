#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

SERVERNAME="${SERVERNAME:-servertest}"
SAVE_DIR="${ROOT_DIR}/data/Saves/Multiplayer/${SERVERNAME}"
DB_FILE="${ROOT_DIR}/data/db/${SERVERNAME}.db"

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

echo "Deleted save and db for ${SERVERNAME}."
