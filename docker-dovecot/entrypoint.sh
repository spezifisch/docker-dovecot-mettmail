#!/bin/bash -e

F="/etc/ssl/private/dovecot.crt"
[ -f "${F}" ] || { echo "!! ${F} missing"; exit 1; }
F="/etc/ssl/private/dovecot.key"
[ -f "${F}" ] || { echo "!! ${F} missing"; exit 1; }

F="/etc/dovecot-auth/passwd"
[ -f "${F}" ] || touch "${F}"
if [ "$(wc -l "${F}" | cut -d' ' -f1)" -eq 0 ]; then
    echo "!! no dovecot virtual users configured"
    echo "!! add users using dovecot-adduser.sh inside the container"
fi

exec "$@"
