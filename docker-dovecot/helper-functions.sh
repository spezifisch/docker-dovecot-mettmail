#!/bin/bash

# Based on: https://github.com/docker-mailserver/docker-mailserver/blob/99cc9fec2a01e078fda6ce439def681e31a4e8f9/target/scripts/helper-functions.sh
# by The Docker Mailserver Organization & Contributors, MIT license

SCRIPT_NAME="$(basename "$0")" # This becomes the sourcing script name (Example: check-for-changes.sh)
LOCK_ID="$(uuid)" # Used inside of lock files to identify them and prevent removal by other instances of docker-mailserver

# ? --------------------------------------------- BIN HELPER

function errex
{
  echo -e "Error :: ${*}\nAborting." >&2
  exit 1
}

function escape
{
  echo "${1//./\\.}"
}

function create_lock
{
  LOCK_FILE="/tmp/${SCRIPT_NAME}.lock"
  while [[ -e "${LOCK_FILE}" ]]
  do
    _notify 'warn' "Lock file ${LOCK_FILE} exists. Another ${SCRIPT_NAME} execution is happening. Trying again shortly..."
    # Handle stale lock files left behind on crashes
    # or premature/non-graceful exits of containers while they're making changes
    if [[ -n "$(find "${LOCK_FILE}" -mmin +1 2>/dev/null)" ]]
    then
      _notify 'warn' "Lock file older than 1 minute. Removing stale lock file."
      rm -f "${LOCK_FILE}"
      _notify 'inf' "Removed stale lock ${LOCK_FILE}."
    fi
    sleep 5
  done
  trap remove_lock EXIT
  echo "${LOCK_ID}" > "${LOCK_FILE}"
}

function remove_lock
{
  LOCK_FILE="${LOCK_FILE:-"/tmp/${SCRIPT_NAME}.lock"}"
  [[ -z "${LOCK_ID}" ]] && errex "Cannot remove ${LOCK_FILE} as there is no LOCK_ID set"
  if [[ -e "${LOCK_FILE}" ]] && grep -q "${LOCK_ID}" "${LOCK_FILE}" # Ensure we don't delete a lock that's not ours
  then
    rm -f "${LOCK_FILE}"
    _notify 'inf' "Removed lock ${LOCK_FILE}."
  fi
}

# ? --------------------------------------------- Notifications

function _notify
{
  { [[ -z ${1:-} ]] || [[ -z ${2:-} ]] ; } && return 0

  local RESET LGREEN LYELLOW LRED RED LBLUE LGREY LMAGENTA

  RESET='\e[0m' ; LGREEN='\e[92m' ; LYELLOW='\e[93m'
  LRED='\e[31m' ; RED='\e[91m' ; LBLUE='\e[34m'
  LGREY='\e[37m' ; LMAGENTA='\e[95m'

  case "${1}" in
    'tasklog'  ) echo "-e${3:-}" "[ ${LGREEN}TASKLOG${RESET} ]  ${2}"  ;;
    'warn'     ) echo "-e${3:-}" "[ ${LYELLOW}WARNING${RESET} ]  ${2}" ;;
    'err'      ) echo "-e${3:-}" "[  ${LRED}ERROR${RESET}  ]  ${2}"    ;;
    'fatal'    ) echo "-e${3:-}" "[  ${RED}FATAL${RESET}  ]  ${2}"     ;;
    'inf'      ) [[ ${DMS_DEBUG} -eq 1 ]] && echo "-e${3:-}" "[[  ${LBLUE}INF${RESET}  ]]  ${2}" ;;
    'task'     ) [[ ${DMS_DEBUG} -eq 1 ]] && echo "-e${3:-}" "[[ ${LGREY}TASKS${RESET} ]]  ${2}" ;;
    *          ) echo "-e${3:-}" "[  ${LMAGENTA}UNKNOWN${RESET}  ]  ${2}" ;;
  esac

  return 0
}
export -f _notify
