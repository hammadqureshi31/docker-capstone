#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./scripts/restore-db.sh <backup-filename-in-backups-dir>"
  exit 1
fi

BACKUP_NAME="$(basename "$1")"
CONTAINER_BACKUP_PATH="/backups/$BACKUP_NAME"

echo "Initiating durable restore for $BACKUP_NAME..."

# Restore directly using the bind-mounted path inside the container
docker exec -t postgres-db pg_restore -U masteryuser -d masterydb --clean --if-exists "$CONTAINER_BACKUP_PATH"

echo "Durable database restoration complete!"
