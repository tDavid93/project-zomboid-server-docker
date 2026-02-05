#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <backup-tar.gz>"
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "*** ERROR: Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

cat <<MSG
This will restore data from:
  - ${BACKUP_FILE}
into:
  - ${ROOT_DIR}
Existing files may be overwritten.
Type 'restore' to continue:
MSG

read -r confirm
if [ "${confirm}" != "restore" ]; then
  echo "Aborted."
  exit 1
fi

cd "${ROOT_DIR}"
tar -xzf "${BACKUP_FILE}"
echo "*** INFO: Restore completed."
