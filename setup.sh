#!/bin/bash

CMD="${1}"
shift

if ! docker-compose ps | grep "entrypoint.sh dovecot" > /dev/null; then
    echo "dovecot container is not running"
    exit 1
fi

case "${CMD}" in
    ( adduser ) docker-compose exec dovecot dovecot-adduser.sh "${@}" ;;
    ( listusers ) docker-compose exec dovecot dovecot-listusers.sh "${@}" ;;
    ( * )
        echo "Usage: ${0} <command> [command args]"
        echo "Commands: adduser, listusers"
        ;;
esac
