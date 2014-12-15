#!/bin/bash

set -e

if [[ ! -f /etc/ldap/docker-configured ]]; then

    if [[ -z "$SLAPD_PASSWORD" ]]; then
	echo >&2 "Error: slapd not configured and SLAPD_PASSWORD not set"
	echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
	exit 1
    fi

    SLAPD_ORG="${SLAPD_ORG:-nodomain}"
    SLAPD_DOMAIN="${SLAPD_DOMAIN:-nodomain}"
    SLAPD_BACKEND="${SLAPD_BACKEND:-MDB}"
    SLAPD_ALLOW_V2="${SLAPD_ALLOW_V2:-false}"
    SLAPD_PURGE_DB="${SLAPD_PURGE_DB:-false}"
    SLAPD_MOVE_OLD_DB="${SLAPD_MOVE_OLD_DB:-true}"

    # Careful with whitespace here. Leading whitespace in the values
    # can cause the configure script for slapd to hang.
    cat <<-EOF | debconf-set-selections
      slapd slapd/no_configuration  boolean false
      slapd slapd/internal/generated_adminpw password $SLAPD_PASSWORD
      slapd slapd/internal/adminpw password $SLAPD_PASSWORD
      slapd slapd/password1         password $SLAPD_PASSWORD
      slapd slapd/password2         password $SLAPD_PASSWORD
      slapd slapd/domain            string $SLAPD_DOMAIN
      slapd shared/organization     string $SLAPD_ORG
      slapd slapd/allow_ldap_v2     boolean $SLAPD_ALLOW_V2
      slapd slapd/purge_database    boolean $SLAPD_PURGE_DB
      slapd slapd/move_old_database boolean $SLAPD_MOVE_OLD_DB
      slapd slapd/purge_database    boolean $SLAPD_PURGE_DB
      slapd slapd/dump_database     select when needed
EOF
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive slapd
    echo "Configuration finished."
    date +%s > /etc/ldap/docker-configured
fi

echo "Starting OpenLDAP"
exec "$@"
