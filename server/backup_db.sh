#!/bin/bash

set -e

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DB_PATH="/home/mark/dih-digital-twin/server/data.db"
BACKUP_PATH="/home/mark/dih-digital-twin/server/backups/data_$TIMESTAMP.db"
LOG_FILE="/home/mark/dih-digital-twin/server/backups/backups.log"

# make backup
cp "$DB_PATH" "$BACKUP_PATH"

# Make backup copy immutable
chattr +i "$BACKUP_PATH"

echo "[$(date '+%Y-%m-%d %H:%M:%S')]: Backup made to $BACKUP_PATH" >> "$LOG_FILE"
