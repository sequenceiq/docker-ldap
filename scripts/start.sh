#!/bin/bash
# Starts up the Phabricator stack within the container.

# Stop on error
set -e

if [[ -e /first_run ]]; then
  source /scripts/first_run.sh
else
  source /scripts/normal_run.sh
fi

pre_start_action
post_start_action

echo "Starting slapd..."
slapd -h "ldap:/// ldapi:///" -u openldap -g openldap -F /etc/ldap/slapd.d -d 0

