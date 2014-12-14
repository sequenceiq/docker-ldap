FROM debian:jessie

MAINTAINER Joshua Lee <muzili@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
  apt-get -y install slapd ldap-utils ldapscripts && \
  rm -rf /var/lib/apt/lists/*

ADD files /ldap
ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Add VOLUMEs to allow backup of config, logs and databases
# * To store the data outside the container, mount /var/lib/ldap as a data volume
VOLUME ["/etc/ldap", "/var/lib/ldap", "/run/slapd"]
EXPOSE 389

ENTRYPOINT ["/entrypoint.sh"]

CMD ["slapd", "-h", "ldap:/// ldapi:///", \
     "-u", "openldap", "-g", "openldap",  \
     "-F", "/etc/ldap/slapd.d", "-d", "0"]
