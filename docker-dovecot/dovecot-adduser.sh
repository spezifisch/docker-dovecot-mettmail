#!/bin/bash

# Based on: https://github.com/docker-mailserver/docker-mailserver/blob/99cc9fec2a01e078fda6ce439def681e31a4e8f9/target/bin/addmailuser
# by The Docker Mailserver Organization & Contributors, MIT license

# shellcheck disable=SC2094

# shellcheck source=./helper-functions.sh
. /usr/local/bin/helper-functions.sh

DATABASE=${DATABASE:-/etc/dovecot-auth/passwd}

function __usage
{
  printf "\e[35mDOVECOT-ADDUSER\e[31m(\e[93m8\e[31m)

\e[38;5;214mNAME\e[39m
    dovecot-adduser.sh - add a dovecot user

\e[38;5;214mSYNOPSIS\e[39m
    dovecot-adduser.sh <USERNAME> [<PASSWORD>]

\e[38;5;214mOPTIONS\e[39m
    \e[94mGeneric Program Information\e[39m
        help       Print the usage information.

\e[38;5;214mEXAMPLES\e[39m
    \e[37mdovecot-adduser.sh test\e[39m
        Add the user account 'test'. You will be prompted
        to input a password afterwards since no password was supplied.

\e[38;5;214mEXIT STATUS\e[39m
    Exit status is 0 if command was successful. If wrong arguments are provided
    or arguments contain errors, the script will exit early with exit status 1.

"
}

[[ ${1:-} == 'help' ]] && { __usage ; exit 0 ; }

FULL_USERNAME="${1}"
shift
PASSWD="${*}"

[[ -z ${FULL_USERNAME} ]] && { __usage ; errex 'No username specified' ; }

touch "${DATABASE}"
create_lock # Protect config file with lock to avoid race conditions
if grep -qi "^$(escape "${FULL_USERNAME}"):" "${DATABASE}"
then
  echo "User '${FULL_USERNAME}' already exists."
  exit 1
fi

if [[ -z ${PASSWD} ]]
then
  read -r -s -p "Enter Password: " PASSWD
  echo
  [[ -z ${PASSWD} ]] && errex "Password must not be empty"
fi

HASH="$(doveadm pw -s SHA512-CRYPT -u "${FULL_USERNAME}" -p "${PASSWD}")"

# database is in dovecot's passwd-file format, each line contains:
# user:password:uid:gid:(gecos):home:(shell):extra_fields
# see: https://doc.dovecot.org/configuration_manual/authentication/passwd_file/
echo "${FULL_USERNAME}:${HASH}::::::" >> "${DATABASE}"
