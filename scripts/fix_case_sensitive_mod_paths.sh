#!/usr/bin/env bash

set -u

STEAMAPPDIR="${STEAMAPPDIR:-/home/steam/pz-dedicated}"
WORKSHOP_ROOT="${WORKSHOP_ROOT:-${STEAMAPPDIR}/steamapps/workshop/content/108600}"

BASE_DEFAULT=""
for candidate in \
  "${STEAMAPPDIR}/media/AnimSets/player/emote/default.xml" \
  "${STEAMAPPDIR}/media/animsets/player/emote/default.xml"
do
  if [ -f "${candidate}" ]; then
    BASE_DEFAULT="${candidate}"
    break
  fi
done

BASE_LOOPED=""
for candidate in \
  "${STEAMAPPDIR}/media/AnimSets/player/emote/looped.xml" \
  "${STEAMAPPDIR}/media/animsets/player/emote/looped.xml"
do
  if [ -f "${candidate}" ]; then
    BASE_LOOPED="${candidate}"
    break
  fi
done

if [ ! -d "${WORKSHOP_ROOT}" ]; then
  echo "*** INFO: Workshop root not found at ${WORKSHOP_ROOT}, skipping case-sensitive fixes."
  exit 0
fi

for mod_dir in "${WORKSHOP_ROOT}"/*/mods/*; do
  [ -d "${mod_dir}" ] || continue
  mod_parent="$(dirname "${mod_dir}")"
  mod_name="$(basename "${mod_dir}")"
  mod_name_lower="$(printf "%s" "${mod_name}" | tr '[:upper:]' '[:lower:]')"

  if [ "${mod_name}" != "${mod_name_lower}" ] && [ ! -e "${mod_parent}/${mod_name_lower}" ]; then
    ln -s "${mod_dir}" "${mod_parent}/${mod_name_lower}"
    echo "*** INFO: Linked ${mod_parent}/${mod_name_lower} -> ${mod_dir}"
  fi

  while IFS= read -r -d '' anim_dir; do
    anim_parent="$(dirname "${anim_dir}")"
    if [ ! -e "${anim_parent}/animsets" ]; then
      ln -s "AnimSets" "${anim_parent}/animsets"
      echo "*** INFO: Linked ${anim_parent}/animsets -> AnimSets"
    fi
  done < <(find "${mod_dir}" -type d -name AnimSets -print0)

  while IFS= read -r -d '' base_xml; do
    base_dir="$(dirname "${base_xml}")"
    base_name="$(basename "${base_xml}")"
    base_lower="$(printf "%s" "${base_name}" | tr '[:upper:]' '[:lower:]')"
    if [ "${base_name}" != "${base_lower}" ] && [ ! -e "${base_dir}/${base_lower}" ]; then
      ln -s "${base_name}" "${base_dir}/${base_lower}"
      echo "*** INFO: Linked ${base_dir}/${base_lower} -> ${base_name}"
    fi
  done < <(
    find "${mod_dir}" -type f \( \
      -name "UseBenchPressVanilla.xml" -o \
      -name "UseTreadmillVanilla.xml" \
    \) -print0
  )

  while IFS= read -r -d '' emote_dir; do
    if [ -n "${BASE_DEFAULT}" ] && [ ! -e "${emote_dir}/default.xml" ]; then
      ln -s "${BASE_DEFAULT}" "${emote_dir}/default.xml"
      echo "*** INFO: Linked ${emote_dir}/default.xml -> ${BASE_DEFAULT}"
    fi
    if [ -n "${BASE_LOOPED}" ] && [ ! -e "${emote_dir}/looped.xml" ]; then
      ln -s "${BASE_LOOPED}" "${emote_dir}/looped.xml"
      echo "*** INFO: Linked ${emote_dir}/looped.xml -> ${BASE_LOOPED}"
    fi
  done < <(find "${mod_dir}" -type d -path "*/AnimSets/player/emote" -print0)
done
