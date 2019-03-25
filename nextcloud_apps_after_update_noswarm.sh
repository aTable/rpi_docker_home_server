#!/bin/bash

APPS="bookmarks calendar contacts gpxedit gpxmotion gpxpod mail passman phonetrack tasks"

echo "See for Passman Error: Certificate \"4120\" has been revoked"
echo "https://github.com/nextcloud/passman/issues/524#issuecomment-469286167"
echo "https://github.com/nextcloud/passman/issues/560"
echo "Go on folder apps"
echo "rm -Rf passman"
echo "wget https://github.com/nextcloud/passman/archive/2.2.1.zip"
echo "apt install unzip"
echo "unzip 2.2.1.zip"
echo "mv passman-2.2.1 passman"
echo "chmod -Rf 755 passman"
echo "chown -Rf www-data:www-data passman"

# ##### Re-enabling apps ###### #
echo ""
echo "Re-enabling apps"

container=$(docker ps | grep nextcloud | cut -f1 -d" ")
#echo Container=$container
if [ -z $container ]; then
    echo "Qué me estás container?!";
    exit 1;
fi

for i in ${APPS}; do
    echo $i;
    docker exec ${container} sh -c 'sudo -u www-data php /var/www/nextcloud/occ app:install '$i;
done;
