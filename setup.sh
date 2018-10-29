#!/bin/bash

DEFAULT_VOLUMES=/media/volumes
PWD_GEN='< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;'
#PWD_GEN='openssl rand -base64 20'
DEFAULT_LDAP_MAIL_UID='mail'
DEFAULT_LDAP_NEXTCLOUD_UID='nextcloud'
DEFAULT_LDAP_GOGS_UID='gogs'

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

read -p "LDAP Gogs Bind DN uid ($DEFAULT_LDAP_GOGS_UID): " ldap_gogs_uid
if [[ ${#ldap_gogs_uid} -eq 0 ]]; then
    ldap_gogs_uid=$DEFAULT_LDAP_GOGS_UID
fi

read -p "LDAP Gogs Bind DN Pwd (a random one will be generated if empty): " ldap_gogs_pwd
if [[ ${#ldap_gogs_pwd} -eq 0 ]]; then
    ldap_gogs_pwd=`eval "$PWD_GEN"`
fi

read -p "Nextcloud Admin User Pwd (a random one will be generated if empty): " nextcloud_admin_pwd
if [[ ${#nextcloud_admin_pwd} -eq 0 ]]; then
    nextcloud_admin_pwd=`eval "$PWD_GEN"`
fi

read -p "Gogs Admin User Pwd (a random one will be generated if empty): " gogs_admin_pwd
if [[ ${#gogs_admin_pwd} -eq 0 ]]; then
    gogs_admin_pwd=`eval "$PWD_GEN"`
fi

read -p "Pi-Hole Web User Pwd (a random one will be generated if empty): " pihole_web_pwd
if [[ ${#pihole_web_pwd} -eq 0 ]]; then
    pihole_web_pwd=`eval "$PWD_GEN"`
fi

read -p "Admin E-mail, used for Let's Encrypt account and more (admin@${domain}): " admin_email
if [[ ${#admin_email} -eq 0 ]]; then
    admin_email=admin@${domain}
fi

echo "If you have a password salt and a secret from a previous installation, provide them here."
echo "They are used by Passman and need to remain the same for the vaults to be accessible"
read -p "Nextcloud Pwd Salt (a random one will be generated by NC if empty): " nextcloud_salt
read -p "Nextcloud Secret (a random one will be generated by NC if empty): " nextcloud_secret

read -p "Paperless Web Server User (paperless): " paperless_webserver_user
if [[ ${#paperless_webserver_user} -eq 0 ]]; then
    paperless_webserver_user=paperless
fi

read -p "Paperless Web Server Pwd (a random one will be generated if empty): " paperless_webserver_pwd
if [[ ${#paperless_webserver_pwd} -eq 0 ]]; then
    paperless_webserver_pwd=`eval "$PWD_GEN"`
fi

read -p "Paperless Encryption Passphrase (a random one will be generated if empty): " paperless_passphrase
if [[ ${#paperless_passphrase} -eq 0 ]]; then
    paperless_=`eval "$PWD_GEN"`
fi

read -p "SFTP User - SFTP server is used by paperless (consume): " paperless_ftp_user
if [[ ${#paperless_ftp_user} -eq 0 ]]; then
    paperless_ftp_user=consume
fi

read -p "SFTP Pwd (a random one will be generated if empty): " paperless_ftp_pwd
if [[ ${#paperless_ftp_pwd} -eq 0 ]]; then
    paperless_ftp_pwd=`eval "$PWD_GEN"`
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
echo Your LDAP Gogs Bind DN Uid is:        $ldap_gogs_uid
echo Your Admin email. Let\'s Encrypt...:  $admin_email
echo Your Paperless Web Server User:       $paperless_webserver_user
echo Your SFTP User:                       $paperless_ftp_user

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
echo $ldap_gogs_pwd | docker secret create ldap_gogs_pwd -
echo $nextcloud_admin_pwd | docker secret create nextcloud_admin_pwd -
echo $nextcloud_salt | docker secret create nextcloud_salt -
echo $nextcloud_secret | docker secret create nextcloud_secret -
echo $paperless_webserver_pwd | docker secret create paperless_webserver_pwd -
echo $paperless_passphrase | docker secret create paperless_passphrase -
echo $paperless_ftp_pwd | docker secret create paperless_ftp_pwd -
echo $gogs_admin_pwd | docker secret create gogs_admin_pwd -
#echo $pihole_web_pwd | docker secret create pihole_web_pwd -
sed -i "s/\${PIHOLE_WEB_PWD}/${pihole_web_pwd}/g" pihole.env

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
cp paperless.env.template paperless.env
cp sftp.env.template sftp.env
cp gogs.env.template gogs.env
cp pihole.env.template pihole.env

# IP for Pi-Hole
IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')"  # May not work for VPN / tun0
IPv6_LOOKUP="$(ip -6 route get 2001:4860:4860::8888 | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"  # May not work for VPN / tun0

for i in `ls *.env .env`; do
    sed -i "s/\${DOMAIN}/${domain}/g" $i
    sed -i "s/\${ORGANIZATION}/${org}/g" $i
    sed -i "s/\${EXTENSION}/${ext}/g" $i
    sed -i "s/\${VOLUMES_PATH}/${volumes//\//\\/}/g" $i
    sed -i "s/\${LDAP_MAIL_UID}/${ldap_mail_uid}/g" $i
    sed -i "s/\${LDAP_NEXTCLOUD_UID}/${ldap_nextcloud_uid}/g" $i
    sed -i "s/\${LDAP_GOGS_UID}/${ldap_gogs_uid}/g" $i
    sed -i "s/\${ADMIN_EMAIL}/${admin_email}/g" $i
    sed -i "s/\${PAPERLESS_WEBSERVER_USER}/${paperless_webserver_user}/g" $i
    sed -i "s/\${PAPERLESS_FTP_USER}/${paperless_ftp_user}/g" $i
    sed -i "s/\${IP_LOOKUP}/${IP_LOOKUP}/g" $i
    sed -i "s/\${IPv6_LOOKUP}/${IPv6_LOOKUP}/g" $i
    #sed -i "s/\${}/${}/g" $i
done;

# read variables
. .env
# repeated env variables
echo "\nMAIL_DATA_PATH=${MAIL_DATA_PATH}" >> mail.env
echo "\nNEXTCLOUD_DB_BACKUP=${NEXTCLOUD_DATA_PATH}/nextcloud_db_backup.sql" >> nextcloud.env
echo "\nNEXTCLOUD_DATA_PATH=${NEXTCLOUD_DATA_PATH}" >> nextcloud.env
echo "\nNEXTCLOUD_BACKUP_PATH=${NEXTCLOUD_BACKUP_PATH}" >> nextcloud.env
echo "\nPAPERLESS_CONSUMPTION_DIR=${PAPERLESS_CONSUMPTION_PATH}" >> paperless.env
echo "\nPAPERLESS_EXPORT_DIR=${PAPERLESS_EXPORT_PATH}" >> paperless.env
echo "\nPAPERLESS_CONSUMPTION_DIR=${PAPERLESS_CONSUMPTION_PATH}" >> sftp.env

echo $'\E[33m'
echo "//////////////////////////////////////////////////"
echo "//////////////// CREATING FOLDERS ////////////////"
echo "//////////////////////////////////////////////////"
echo $'\E[1;30m'

# openldap
sudo mkdir -p ${LDAP_DATA_VOLUME_PATH}
sudo mkdir -p ${LDAP_CONFIG_VOLUME_PATH}
sudo mkdir -p ${LDAP_CERTS_VOLUME_PATH}
# db
sudo mkdir -p ${DB_DATA_VOLUME_PATH}
#sudo mkdir -p ${DB_CONFIG_VOLUME_PATH}
# mail
sudo mkdir -p ${MAIL_DATA_VOLUME_PATH}
sudo mkdir -p ${MAIL_DATA_VOLUME_PATH}/getmail
#sudo mkdir -p ${MAIL_STATE_VOLUME_PATH}
# nextcloud
sudo mkdir -p ${NEXTCLOUD_DATA_VOLUME_PATH}
sudo mkdir -p ${NEXTCLOUD_BACKUP_VOLUME_PATH}
# paperless
sudo mkdir -p ${PAPERLESS_DATA_VOLUME_PATH}
sudo mkdir -p ${PAPERLESS_MEDIA_VOLUME_PATH}
sudo mkdir -p ${PAPERLESS_CONSUMPTION_VOLUME_PATH}
sudo mkdir -p ${PAPERLESS_EXPORT_VOLUME_PATH}
# gogs
sudo mkdir -p ${GOGS_DATA_VOLUME_PATH}
# Pi-Hole
sudo mkdir -p ${PIHOLE_CONFIG_VOLUME_PATH}
sudo mkdir -p ${PIHOLE_DNSMASQ_VOLUME_PATH}
# let's Encrypt
sudo mkdir -p ${LETSENCRYPT_VOLUME_PATH}

echo "Copying getmail confs"
cp images/email/getmail/getmailrc-* ${MAIL_DATA_VOLUME_PATH}/getmail/
