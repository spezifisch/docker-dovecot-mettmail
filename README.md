# docker-dovecot-mettmail

***docker-dovecot-mettmail*** is a [*Docker*](http://www.docker.com/) image based on *Debian* implementing a private email gateway with [*dovecot*](http://en.wikipedia.org/wiki/Dovecot_(software)) and [*mettmail*](https://github.com/spezifisch/mettmail) for gathering emails from multiple accounts on a private server (IMAP), but using a public email infrastructure for sending (SMTP).

```
+-----------+              +-----------+               +--------------+
| ISP       |              | DOCKER    |               | LAPTOP       |
|           |              |           |           +-->|--------------|
| +-------+ | push/delete  | +-------+ | push/sync |   |  MAIL CLIENT +---+
| | IMAPS +----------------->| IMAPS +<------------+   +--------------+   |
| +-------+ |              | +-------+ |           |   +--------------+   |
| +-------+ |              |           |           |   | ANDROID      |   |
| | SMTP  |<-------+       |           |           +-->|--------------|   |
| +-------+ |      |       |           |               |  MAIL CLIENT +---+
+-----------+      |       +-----------+               +--------------+   |
                   +------------------------------------------------------+
```

## In Development

[*Mettmail*](https://github.com/spezifisch/mettmail) is currently in active development. This repository uses the latest stable release.

## Usage

Note: You can use the included `docker-compose.yaml` as a starting point. In general you need to do the following to get this setup working:

* Create `mettmail-NAME.yaml` files for the email accounts you want to fetch and put them into the `config` directory. See the `example-config` directory.
* Add a container configuration for each `mettmail.yaml` in `docker-compose.yaml` based on the pattern in `docker-compose.test.yaml`. Use your `mettmail-NAME.yaml` in volume configuration instead of the example file.
* Get or create SSL certificates and put them into the `data/ssl` directory as `dovecot.crt` and `dovecot.key`.
* Start everything using `docker-compose up -d`
* Create dovecot users using `./setup.sh adduser USER` and enter a password when prompted.
* You can now connect to IMAPS on port 993 using those credentials. Sieve is available on 4190.

## Container Overview

### dovecot

Requirements for dovecot container:

* `/srv/vmail`: volume with user maildirs
* `/etc/dovecot-auth`: volume containing dovecot's [passwd-file](https://doc.dovecot.org/configuration_manual/authentication/passwd_file/)
* `/etc/ssl/private`: mounted SSL/TLS certificates (`dovecot.crt`, `dovecot.key`)

#### Users

Users can be created with `./setup.sh adduser`. The password are stored hashed using SHA512-CRYPT in `/etc/dovecot-auth/passwd`. You can also use the helper script `dovecot-adduser.sh` inside the dovecot container or edit that file directly, e.g. to [override fields](https://doc.dovecot.org/configuration_manual/authentication/user_databases_userdb/) like quota.

### mettmail

Requirements for mettmail containers:

* `/config/mettmail.yaml`: bind-mounted mettmail config file

Base your `mettmail.yaml` on those in the `example-config` directory.

## Test Setup

There is a test setup included for development purposes. You normally don't need to use this. After generating SSL certificates and placing them in `data/ssl` (see instructions in `docker-compose.test.yaml`) you can start the dovecot server using:

```shell
docker-compose up
```

Then you need to create a user in the dovecot container (username `test` is configured in the example `mettmail.yaml` but it doesn't yet exist in the dovecot container):

```shell
./setup.sh adduser test test
```

After this initial setup, stop the dovecot server and restart the final test setup:

```shell
docker-compose down
docker-compose -f docker-compose.yaml -f docker-compose.test.yaml up
```

This starts:

* A separate `testcot` container ([docker-test-dovecot](https://github.com/spezifisch/docker-test-dovecot)) with a dovecot listening docker-internally. There are dovecot users `a, b, c, d`, each with password `pass`. A script is started generating a new mail every minute for each user if that user currently has no new mails. This way we have something for mettmail to fetch every minute.
* [mettmail](https://github.com/spezifisch/mettmail) containers which connect to `testcot` and receive mails for users `a, b, c`. The mails are delivered to user `test` in the dovecot container.

You can then connect to the `dovecot` container using username `test` with password `test` and see the generated mails which were fetched and delivered by mettmail.

If you run into trouble make sure to bring down the whole setup (`docker-compose -f docker-compose.yaml -f docker-compose.test.yaml down`) before restarting it.

## Fork of docker-dovecot-getmail

Differences to https://github.com/gw0/docker-dovecot-getmail:

* upgraded Debian 10/buster to Debian 11/bullseye
* using [*mettmail*](https://github.com/spezifisch/mettmail) instead of getmail4
* local delivery from mettmail to dovecot using LMTP (instead of [LDA](https://doc.dovecot.org/configuration_manual/protocols/lda/))
* runs each mettmail instance in its own docker container (instead of using cron)
* uses dovecot virtual users from passwd-file managed by convenience script `setup.sh` (instead of using PAM with unix users)

## License

* Copyright &copy; 2021-2022 *spezifisch* [https://github.com/spezifisch/]
* Copyright &copy; 2016-2021 *gw0* [<http://gw.tnode.com/>] &lt;<gw.2021@ena.one>&gt;

This library is licensed under the [GNU Affero General Public License 3.0+](LICENSE) (AGPL-3.0+). Note that it is mandatory to make all modifications and complete source code of this library publicly available to any user.
