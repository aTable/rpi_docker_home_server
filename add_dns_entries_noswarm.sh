#!/bin/bash

echo ""
echo "Adding DNS entries to PI-HOLE"

CONF_FILE=custom_dnsmasq.conf

IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')"  # May not work for VPN / tun0

# read variables, for domain and host names
source .env

# global domain
echo server=/${LDAP_DOMAIN}/${IP_LOOKUP} > /tmp/${CONF_FILE}
# mail
echo address=/${MAIL_HOSTNAME}.${LDAP_DOMAIN}/${IP_LOOKUP} > /tmp/${CONF_FILE}
# Nextcloud
echo address=/${NEXTCLOUD_SERVER_NAME}.${LDAP_DOMAIN}/${IP_LOOKUP} >> /tmp/${CONF_FILE}
# gogs
echo address=/gogs.${LDAP_DOMAIN}/${IP_LOOKUP} >> /tmp/${CONF_FILE}

# ##### Add entries to PiHole ###### #

container=$(docker ps | grep pihole | cut -f1 -d" ")
#echo Container=$container
if [ -z $container ]; then
    echo "Qué me estás container?!";
    exit 1;
fi

echo Copying user files to Container $container
docker cp /tmp/${CONF_FILE} $container:/etc/dnsmasq.d/99-local-addresses.conf
# restart dns
docker exec ${container} pihole restartdns

echo Removing copied user files
docker exec ${container} sh -c 'rm -Rf /tmp/${CONF_FILE}'
rm -Rf /tmp/${CONF_FILE}
