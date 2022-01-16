#!/bin/bash

# Based on: https://github.com/docker-mailserver/docker-mailserver/blob/99cc9fec2a01e078fda6ce439def681e31a4e8f9/target/bin/addmailuser
# by The Docker Mailserver Organization & Contributors, MIT license

# shellcheck source=./helper-functions.sh
. /usr/local/bin/helper-functions.sh

DATABASE=${DATABASE:-/etc/dovecot-auth/passwd}

[ ! -e "${DATABASE}" ] && errex "user database doesn't exist"

echo "Dovecot users:"
cut -d'|' -f1 "${DATABASE}"
