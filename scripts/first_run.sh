pre_start_action() {
    if [[ -z "$SLAPD_PASSWORD" ]]; then
	echo >&2 "Error: slapd not configured and SLAPD_PASSWORD not set"
	echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
	exit 1
    fi
    
    TLS_REQCERT="${TLS_REQCERT:-never}"
    SLAPD_ORG="${SLAPD_ORG:-nodomain}"
    SLAPD_DOMAIN="${SLAPD_DOMAIN:-nodomain}"
    SLAPD_DC="${SLAPD_DC:-dc=nodomain}"
    SLAPD_BACKEND="${SLAPD_BACKEND:-MDB}"
    SLAPD_ALLOW_V2="${SLAPD_ALLOW_V2:-false}"
    SLAPD_PURGE_DB="${SLAPD_PURGE_DB:-false}"
    SLAPD_MOVE_OLD_DB="${SLAPD_MOVE_OLD_DB:-true}"
    SLAPD_BINDUSER="${SLAPD_BINDUSER:-binduser}"
    SLAPD_BINDPWD="${SLAPD_BINDPWD:-bindpassword}"
    SLAPD_BINDGROUP="${SLAPD_BINDGROUP:-bindgroup}"
#    SLAPD_BINDPWD=$(slappasswd -s $SLAPD_BINDPWD)

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
      slapd slapd/backend           string $SLAPD_BACKEND
      slapd slapd/dump_database     select when needed
EOF
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive slapd
    service slapd start
    mkdir -p /etc/ldapscripts
    cat > /etc/ldapscripts/ldapscripts.conf <<EOF
SERVER="localhost"
SUFFIX="$SLAPD_DC" # Global suffix
GSUFFIX="ou=groups"        # Groups ou (just under $SUFFIX)
USUFFIX="ou=users"         # Users ou (just under $SUFFIX)
MSUFFIX="ou=machines"      # Machines ou (just under $SUFFIX)
SASLAUTH=""
BINDDN="cn=admin,$SLAPD_DC"
BINDPWDFILE="/etc/ldapscripts/ldapscripts.passwd"
GIDSTART="10000" # Group ID
UIDSTART="10000" # User ID
MIDSTART="20000" # Machine ID
GCLASS="posixGroup"   # Leave "posixGroup" here if not sure !
CREATEHOMES="no"      # Create home directories and set rights ?
PASSWORDGEN="pwgen"
RECORDPASSWORDS="no"
PASSWORDFILE="/var/log/ldapscripts_passwd.log"
LOGFILE="/var/log/ldapscripts.log"
GTEMPLATE="/etc/ldapscripts/ldapaddgroup.template"
UTEMPLATE="/etc/ldapscripts/ldapadduser.template"
MTEMPLATE="/etc/ldapscripts/ldapaddmachine.template"
LDAPSEARCHBIN="/usr/bin/ldapsearch"
LDAPADDBIN="/usr/bin/ldapadd"
LDAPDELETEBIN="/usr/bin/ldapdelete"
LDAPMODIFYBIN="/usr/bin/ldapmodify"
LDAPMODRDNBIN="/usr/bin/ldapmodrdn"
LDAPPASSWDBIN="/usr/bin/ldappasswd"
EOF
    echo -n $SLAPD_PASSWORD > /etc/ldapscripts/ldapscripts.passwd
    chmod 400 /etc/ldapscripts/ldapscripts.passwd
    cat > /etc/ldapscripts/create_users_and_groups.ldif <<EOF
dn: ou=users,$SLAPD_DC
objectClass: organizationalUnit
ou: users

dn: ou=groups,$SLAPD_DC
objectClass: organizationalUnit
ou: groups

dn: ou=roles,$SLAPD_DC
objectClass: organizationalUnit
ou: roles

dn: ou=projects,$SLAPD_DC
objectClass: organizationalUnit
ou: projects
EOF
    echo "TLS_REQCERT $TLS_REQCERT" >> /etc/ldap/ldap.conf
    ldapadd -w $SLAPD_PASSWORD -x -D cn=admin,$SLAPD_DC -f /etc/ldapscripts/create_users_and_groups.ldif
    ldapaddgroup $SLAPD_BINDGROUP
    ldapadduser ${SLAPD_BINDUSER} $SLAPD_BINDGROUP
    ldapsetpasswd ${SLAPD_BINDUSER} $(slappasswd -s ${SLAPD_BINDPWD})
    kill -TERM `cat /var/run/slapd/slapd.pid`
    echo "Configuration finished."
}

post_start_action() {
    rm /first_run
}
