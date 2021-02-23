#!/bin/sh

#=====================================================================
# Set the following variables as per your requirement
#=====================================================================
# Database Name to backup
MONGO_HOST="192.168.109.138"
# Database port
MONGO_PORT="27017"
# Backup directory
BACKUPS_DIR="/var/backups/$MONGO_DATABASE"
DAYSTORETAINBACKUP="365"
#=====================================================================

TIMESTAMP=`date +%F-%H%M`
BACKUP_NAME="$TIMESTAMP"

echo "Performing backup of $MONGO_DATABASE"
echo "--------------------------------------------"
# Create backup directory
if ! mkdir -p $BACKUPS_DIR; then
  echo "Can't create backup directory in $BACKUPS_DIR. Go and fix it!" 1>&2
  exit 1;
fi;
# Create dump
mongodump --host $MONGO_HOST:$MONGO_PORT
# Rename dump directory to backup name
mv dump $BACKUP_NAME
# Compress backup
tar -zcvf $BACKUPS_DIR/$BACKUP_NAME.tgz $BACKUP_NAME
# Delete uncompressed backup
rm -rf $BACKUP_NAME
# Delete backups older than retention period
find $BACKUPS_DIR -type f -mtime +$DAYSTORETAINBACKUP -exec rm {} +
echo "--------------------------------------------"
echo "Database backup complete!"
