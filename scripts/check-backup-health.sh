#!/usr/bin/env bash
BACKUP_DIR="/home/hammad/projects/docker-capstone/backups"
MAX_AGE_MINUTES=10

# Find the newest custom format dump backup file
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/masterydb_full_*.dump 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
  echo "[ALERT] No database backups found!"
  exit 1
fi

# Check age of the latest backup in minutes
FILE_AGE_MIN=$(( ( $(date +%s) - $(stat -c %Y "$LATEST_BACKUP") ) / 60 ))

if [ $FILE_AGE_MIN -gt $MAX_AGE_MINUTES ]; then
  echo "[ALERT] Backup is stale! Latest backup is $FILE_AGE_MIN minutes old."
  exit 1
else
  echo "[OK] Backup health check passed. Latest backup is $FILE_AGE_MIN minutes old."
  exit 0
fi
