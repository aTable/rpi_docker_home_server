#!/bin/bash

DEFAULT_VOLUMES=/media/volumes
PWD_GEN='< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;'
#PWD_GEN='openssl rand -base64 20'
DEFAULT_LDAP_MAIL_UID='mail'
DEFAULT_LDAP_NEXTCLOUD_UID='nextcloud'

read -p "Main domain: " domain
while [[ ! $domain =~ ^.*\.[a-z]{2,}$ ]]; do
    read -p "Please Enter a valid domain: " domain
done
# TODO: more than 1 level domains
org=`echo $domain | cut -f1 -d'.'`
ext=`echo $domain | cut -f2 -d'.'`

read -p "Volumes path ($DEFAULT_VOLUMES): " volumes
if [[ ${#volumes} -eq 0 ]]; then
    volumes=$DEFAULT_VOLUMES
fi

read -p "DB admin password (a random one will be generated if empty): " db_pwd
if [[ ${#db_pwd} -eq 0 ]]; then
    db_pwd=`eval "$PWD_GEN"`
fi

read -p "LDAP admin password (a random one will be generated if empty): " ldap_pwd
if [[ ${#ldap_pwd} -eq 0 ]]; then
    ldap_pwd=`eval "$PWD_GEN"`
fi

read -p "LDAP Mail Bind DN uid ($DEFAULT_LDAP_MAIL_UID): " ldap_mail_uid
if [[ ${#ldap_mail_uid} -eq 0 ]]; then
    ldap_mail_uid=$DEFAULT_LDAP_MAIL_UID
fi

read -p "LDAP Mail Bind DN Pwd (a random one will be generated if empty): " ldap_mail_pwd
if [[ ${#ldap_mail_pwd} -eq 0 ]]; then
    ldap_mail_pwd=`eval "$PWD_GEN"`
fi

read -p "LDAP Nextcloud Bind DN uid ($DEFAULT_LDAP_NEXTCLOUD_UID): " ldap_nextcloud_uid
if [[ ${#ldap_nextcloud_uid} -eq 0 ]]; then
    ldap_nextcloud_uid=$DEFAULT_LDAP_NEXTCLOUD_UID
fi

read -p "LDAP Nextcloud Bind DN Pwd (a random one will be generated if empty): " ldap_nextcloud_pwd
if [[ ${#ldap_nextcloud_pwd} -eq 0 ]]; then
    ldap_nextcloud_pwd=`eval "$PWD_GEN"`
fi

read -p "Nextcloud Admin User Pwd (a random one will be generated if empty): " nextcloud_admin_pwd
if [[ ${#nextcloud_admin_pwd} -eq 0 ]]; then
    nextcloud_admin_pwd=`eval "$PWD_GEN"`
fi

echo $'\E[33m'
echo "//////////////////////////////////////////////////"
echo "///////////////// PLEASE CONFIRM /////////////////"
echo "//////////////////////////////////////////////////"
echo $'\E[1;30m'

echo Your domain is:                       $domain
echo Your Volumes path is:                 $volumes
echo Your LDAP Mail Bind DN Uid is:        $ldap_mail_uid
echo Your LDAP Nextcloud Bind DN Uid is:   $ldap_nextcloud_uid

echo $'\E[1;37m'
read -p "Are These Settings Correct? Yes (y), No (n): " confirm
while [[ ! $confirm =~ ^[yYnN]{1}$ ]]; do
    read -p "Please Enter 'y' or 'n' To Confirm Settings: " confirm
done

if [[ $confirm != [yY] ]]; then
    exit 1
fi

# Generate docker secrets
echo $db_pwd | docker secret create db_pwd -
echo $ldap_pwd | docker secret create ldap_pwd -
echo $ldap_mail_pwd | docker secret create ldap_mail_pwd -
echo $ldap_nextcloud_pwd | docker secret create ldap_nextcloud_pwd -
echo $nextcloud_admin_pwd | docker secret create nextcloud_admin_pwd -

echo $'\E[33m'
echo "//////////////////////////////////////////////////"
echo "///////////// COPYING TEMPLATE FILES /////////////"
echo "//////////////////////////////////////////////////"
echo $'\E[1;30m'

cp env.template .env
cp openldap.env.template openldap.env
cp mail.env.template mail.env
cp nextcloud.env.template nextcloud.env
cp haproxy.env.template haproxy.env

for i in `ls *.env .env`; do
    sed -i "s/\${DOMAIN}/${domain}/g" $i
    sed -i "s/\${ORGANIZATION}/${org}/g" $i
    sed -i "s/\${EXTENSION}/${ext}/g" $i
    sed -i "s/\${VOLUMES_PATH}/${volumes//\//\\/}/g" $i
    sed -i "s/\${MAIL_LDAP_UID}/${ldap_mail_uid}/g" $i
    sed -i "s/\${NEXTCLOUD_LDAP_UID}/${ldap_nextcloud_uid}/g" $i
    #sed -i "s/\${}/$/g" $i
done;

# read variables
. .env
# repeated env variables
echo "\nNEXTCLOUD_DB_BACKUP=${NEXTCLOUD_DATA_PATH}/nextcloud_db_backup.sql" >> nextcloud.env
echo "\nMAIL_DATA_PATH=${MAIL_DATA_PATH}" >> mail.env
echo "\nNEXTCLOUD_DATA_PATH=${NEXTCLOUD_DATA_PATH}" >> nextcloud.env

echo $'\E[33m'
echo "//////////////////////////////////////////////////"
echo "//////////////// CREATING FOLDERS ////////////////"
echo "//////////////////////////////////////////////////"
echo $'\E[1;30m'

# openldap
sudo mkdir -p ${LDAP_DATA_PATH}
sudo mkdir -p ${LDAP_CONFIG_PATH}
sudo mkdir -p ${LDAP_CERTS_PATH}
# db
sudo mkdir -p ${DB_DATA_PATH}
#sudo mkdir -p ${DB_CONFIG_PATH}
# mail
sudo mkdir -p ${MAIL_DATA_PATH}
sudo mkdir -p ${MAIL_STATE_PATH}
# nextcloud
sudo mkdir -p ${NEXTCLOUD_DATA_PATH}
