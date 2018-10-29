#!/bin/bash

# ##### Add users to LDAP ###### #
echo ""
echo "Adding users to LDAP"

container=$(docker ps | grep openldap | cut -f1 -d" ")
#echo Container=$container
if [ -z $container ]; then
    echo "Qué me estás container?!";
    exit 1;
fi

# read variables, for mail data path
. .env
# Replace Mail data path for users
find images/openldap/users -type f -exec \
     sed -i "s/\${MAIL_DATA_PATH}/${MAIL_DATA_PATH//\//\\/}/g" {} \;

echo Copying user files to Host $host
mkdir -p /tmp/users
cp -r images/openldap/users/userimport*.ldif /tmp/users/

echo Copying user files to Container $container in Host $host
docker cp /tmp/users $container:/tmp/

echo Adding users to openldap
for i in $(ls /tmp/users/userimport*.ldif); do
    ls $i;
    docker exec ${container} sh -c 'slapadd -l '$i;
done;
#'ldapadd -w \$(cat \${LDAP_ADMIN_PWD_FILE}) -D cn=admin,dc=\${LDAP_ORGANIZATION},dc=\${LDAP_EXTENSION} -f '\$i; \

echo Removing copied user files
docker exec ${container} sh -c 'rm -Rf /tmp/users'
rm -Rf /tmp/users
