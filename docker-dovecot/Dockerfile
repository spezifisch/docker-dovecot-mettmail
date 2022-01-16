# Private email gateway with getmail6 and dovecot
#
# Based on https://github.com/gw0/docker-dovecot-getmail by gw0 [http://gw.tnode.com/] <gw.2021@ena.one>

FROM debian:bullseye-slim

# install debian packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
    dovecot-imapd \
    dovecot-lmtpd \
    dovecot-managesieved \
    uuid \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# configure dovecot
    # log to stderr
RUN sed -i 's/#log_path = syslog/log_path = \/dev\/stderr/' /etc/dovecot/conf.d/10-logging.conf \
    # authentication
 && sed -i 's/#auth_verbose =.*/auth_verbose = yes/' /etc/dovecot/conf.d/10-logging.conf \
    # remove other authentication methods (we add 50-auth-passwd.conf below)
 && sed -i '/^!include/d' /etc/dovecot/conf.d/10-auth.conf \
 && rm /etc/dovecot/conf.d/auth*.conf.ext \
    # no ipv6 listeners (useless inside docker)
 && sed -i 's/#listen.*/listen = */' /etc/dovecot/dovecot.conf \
    # ssl
 && sed -i 's/^ssl =.*/ssl = required/' /etc/dovecot/conf.d/10-ssl.conf \
 && sed -i 's/#\?ssl_cert =.*/ssl_cert = <\/etc\/ssl\/private\/dovecot.crt/' /etc/dovecot/conf.d/10-ssl.conf \
 && sed -i 's/#\?ssl_key =.*/ssl_key = <\/etc\/ssl\/private\/dovecot.key/' /etc/dovecot/conf.d/10-ssl.conf \
    # mailboxes
 && sed -i 's/^mail_location =.*/mail_location = maildir:~\/Maildir:LAYOUT=fs/' /etc/dovecot/conf.d/10-mail.conf \
 && sed -i 's/#separator = $/separator = \//' /etc/dovecot/conf.d/10-mail.conf \
    # lmtp for getmail
 && sed -i 's/#inet_listener lmtp.*/inet_listener lmtp {\naddress = 0.0.0.0\nport = 24\n}/' /etc/dovecot/conf.d/10-master.conf \
 && sed -i 's/#lda_mailbox_autocreate =.*/lda_mailbox_autocreate = yes/' /etc/dovecot/conf.d/15-lda.conf \
 && sed -i 's/#lda_mailbox_autosubscribe =.*/lda_mailbox_autosubscribe = yes/' /etc/dovecot/conf.d/15-lda.conf \
 && echo 'protocols = $protocols lmtp' >> /etc/dovecot/conf.d/15-lda.conf \
    # sieve plugin
 && sed -i 's/#mail_plugins = \$mail_plugins/mail_plugins = \$mail_plugins sieve/' /etc/dovecot/conf.d/15-lda.conf \
 && sed -i 's/#protocols = \$protocols sieve/protocols = \$protocols sieve/g' /etc/dovecot/conf.d/20-managesieve.conf \
    # imap idle
 && sed -i 's/#imap_idle_notify_interval =.*/imap_idle_notify_interval = 29 mins/' /etc/dovecot/conf.d/20-imap.conf \
    # no imap listener without ssl
 && sed -i 's/#port = 143$/port = 0/' /etc/dovecot/conf.d/10-master.conf

# fix permission issues with stats-writer, add dovecot passwd auth
COPY dovecot-conf.d/20-stats.conf \
     dovecot-conf.d/50-auth-passwd.conf \
     /etc/dovecot/conf.d/

# create user for virtual mailboxes
RUN groupadd -g 5000 vmail \
 && useradd -u 5000 -g vmail -s /usr/sbin/nologin -k /dev/null -d /srv/vmail -m vmail

# copy scripts
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

COPY dovecot-adduser.sh \
     dovecot-listusers.sh \
     helper-functions.sh \
     /usr/local/bin/
RUN chmod +x /usr/local/bin/dovecot-*.sh

# NOT exposing port 24/lmtp as it's only for internal use
EXPOSE 993
EXPOSE 4190

# contains dovecot's passwd file
VOLUME /etc/dovecot-auth
# contains dovecot's ssl certs (dovecot.key, dovecot.crt)
VOLUME /etc/ssl/private
# contains virtual users and their maildirs
VOLUME /srv/vmail

ENTRYPOINT ["/entrypoint.sh"]
CMD ["dovecot", "-F"]