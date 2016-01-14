You can perform initial configuration of OpenLDAP through the
following environment variables:

```
SLAPD_PASSWORD
TLS_REQCERT (default: never)
SLAPD_ORG (default: nodomain)
SLAPD_DOMAIN (default: nodomain)
SLAPD_BACKEND (default: MDB)
SLAPD_ALLOW_V2 (default: false)
SLAPD_PURGE_DB (default: false)
SLAPD_MOVE_OLD_DB (default: true)
```

Setting `SLAPD_PASSWORD` to configure the admin password is required.
After the initial setup, a flag file, `/etc/ldap/docker-configured`,
will be created containing the current timestamp, and no further
attempts to reconfigure `slapd` will be made as long as that file
exists.
