#!/bin/bash

set -e

DAYS_TO_KEEP=$(( 14 - 1))
TARGET_DIR=/data/backup

# *sigh*
MYSQL_DB=$(php5 -r "$(grep wgDBname  /data/LocalSettings.php; echo 'print $wgDBname;';)")
MYSQL_HOST=$(php5 -r "$(grep wgDBserver /data/LocalSettings.php; echo 'print $wgDBserver;';)")
MYSQL_USER=$(php5 -r "$(grep wgDBadmin /data/LocalSettings.php; echo 'print $wgDBadminuser;';)")
MYSQL_PASSWD=$(php5 -r "$(grep wgDBadmin /data/LocalSettings.php; echo 'print $wgDBadminpassword;';)")

echo "Backing up mediawiki database…"

FILENAME=wiki-$(date '+%Y%m%d').sql.xz
TARGET_FILE=$TARGET_DIR/$FILENAME
nice -n19 mysqldump -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASSWD $MYSQL_DB --opt -c | nice -n19 xz -c > $TARGET_FILE
md5sum $TARGET_FILE > $TARGET_FILE.md5sum
chmod 600 $TARGET_DIR/*.sql.xz

echo "Purging old backups…"

find $TARGET_DIR -type f -mtime +$DAYS_TO_KEEP -exec rm -v {} \;

echo "done!"
