#!/bin/bash
set -euo pipefail

SERVERNAME="${SERVERNAME:-servertest}"
ZOMBOID_DIR="${ZOMBOID_DIR:-/home/steam/Zomboid}"
SERVER_INI="${ZOMBOID_DIR}/Server/${SERVERNAME}.ini"
STEAMCMDDIR="${STEAMCMDDIR:-/home/steam/steamcmd}"
STEAMAPPDIR="${STEAMAPPDIR:-/home/steam/pz-dedicated}"
WORKSHOP_APPID="${WORKSHOP_APPID:-108600}"

CHECK_INTERVAL="${AUTOUPDATE_INTERVAL:-1800}"
START_DELAY="${AUTOUPDATE_START_DELAY:-300}"
BACKUP_ON_UPDATE="${AUTOUPDATE_BACKUP:-1}"
GRACE_SECONDS="${AUTOUPDATE_GRACE_SECONDS:-1800}"
GRACE_POLL="${AUTOUPDATE_GRACE_POLL:-60}"
RCON_HOST="${RCON_HOST:-127.0.0.1}"
RCON_PORT="${RCON_PORT:-27015}"
RCON_PASSWORD="${RCON_PASSWORD:-}"
RCON_ENABLED="${RCON_ENABLED:-0}"
GRACE_ANNOUNCE_INTERVAL="${AUTOUPDATE_GRACE_ANNOUNCE_INTERVAL:-300}"

WORKSHOP_ACF="/home/steam/Steam/steamapps/workshop/appworkshop_${WORKSHOP_APPID}.acf"

if [ "${RCON_ENABLED}" = "1" ] && ! command -v mcrcon >/dev/null 2>&1; then
  if ! command -v python3 >/dev/null 2>&1 || [ ! -x /server/scripts/rcon_client.py ]; then
    echo "*** WARN: RCON enabled but python client is unavailable; disabling RCON broadcasts."
    RCON_ENABLED="0"
  fi
fi

read_workshop_items() {
  if [ ! -f "${SERVER_INI}" ]; then
    echo ""
    return
  fi
  awk -F= '/^WorkshopItems=/{print $2}' "${SERVER_INI}"
}

hash_acf() {
  if [ -f "${WORKSHOP_ACF}" ]; then
    sha256sum "${WORKSHOP_ACF}" | awk '{print $1}'
  else
    echo "missing"
  fi
}

latest_user_log() {
  local logs_root="${ZOMBOID_DIR}/Logs"
  if [ ! -d "${logs_root}" ]; then
    echo ""
    return
  fi
  find "${logs_root}" -type f -name "*_user.txt" -printf "%T@ %p\n" 2>/dev/null \
    | sort -nr \
    | head -n1 \
    | cut -d' ' -f2-
}

players_online() {
  local log_file
  log_file="$(latest_user_log)"
  if [ -z "${log_file}" ] || [ ! -f "${log_file}" ]; then
    echo "0"
    return
  fi
  awk '
    /"[^"]+" fully connected/ { online[$2]=1 }
    /"[^"]+" disconnected player/ { delete online[$2] }
    END { print length(online) }
  ' "${log_file}"
}

wait_for_grace_or_empty() {
  if [ "${GRACE_SECONDS}" -le 0 ]; then
    return 0
  fi

  local remaining="${GRACE_SECONDS}"
  local last_announce=0
  echo "*** INFO: Grace period started (${GRACE_SECONDS}s)."
  while [ "${remaining}" -gt 0 ]; do
    if [ "$(players_online)" -eq 0 ]; then
      echo "*** INFO: No players online; restarting immediately."
      return 0
    fi
    if [ "${RCON_ENABLED}" = "1" ]; then
      local elapsed=$((GRACE_SECONDS - remaining))
      if [ "${elapsed}" -ge "${last_announce}" ]; then
        local minutes=$(( (remaining + 59) / 60 ))
        rcon_say "Server mods updated. Auto-restart in about ${minutes} minute(s) unless server becomes empty."
        last_announce=$((last_announce + GRACE_ANNOUNCE_INTERVAL))
      fi
    fi
    sleep "${GRACE_POLL}"
    remaining=$((remaining - GRACE_POLL))
  done
  echo "*** INFO: Grace period ended; restarting now."
  return 0
}

rcon_cmd() {
  if [ "${RCON_ENABLED}" != "1" ] || [ -z "${RCON_PASSWORD}" ]; then
    return 0
  fi
  /server/scripts/rcon_client.py \
    --host "${RCON_HOST}" \
    --port "${RCON_PORT}" \
    --password "${RCON_PASSWORD}" \
    "$@" 2>/dev/null || true
}

rcon_say() {
  rcon_cmd "servermsg \"${1}\""
}

run_steamcmd_update() {
  local items_raw="$1"
  local cmd_file
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
    echo "*** WARN: steamcmd update failed; will retry on next interval."
  fi
  rm -f "${cmd_file}"
}

if [ "${START_DELAY}" -gt 0 ]; then
  sleep "${START_DELAY}"
fi

while true; do
  items_raw="$(read_workshop_items)"
  if [ -z "${items_raw}" ]; then
    sleep "${CHECK_INTERVAL}"
    continue
  fi

  before_hash="$(hash_acf)"
  run_steamcmd_update "${items_raw}"
  after_hash="$(hash_acf)"

  if [ "${before_hash}" != "${after_hash}" ]; then
    echo "*** INFO: Workshop update detected; evaluating restart window."
    if [ "$(players_online)" -gt 0 ]; then
      rcon_say "Server mods updated. Restart pending; waiting for players or grace window."
      wait_for_grace_or_empty
    else
      echo "*** INFO: No players online; restarting immediately."
    fi
    if [ "${BACKUP_ON_UPDATE}" = "1" ]; then
      /server/scripts/backup_container.sh || true
    fi
    pkill -TERM -f start-server.sh || true
    exit 0
  fi

  sleep "${CHECK_INTERVAL}"
done
