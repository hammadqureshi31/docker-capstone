#!/usr/bin/env bash
set -e

# Since /backups is bind-mounted to host's ./backups directory
CONTAINER_BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$CONTAINER_BACKUP_DIR/masterydb_full_$TIMESTAMP.dump"

echo "[$(date)] Starting durable backup inside postgres-db..."

# Execute pg_dump directly targeting the bind-mounted directory
docker exec -t postgres-db pg_dump -U masteryuser -d masterydb -F c -f "$BACKUP_FILE"

echo "[$(date)] Durable backup successfully created on host at: ./backups/masterydb_full_$TIMESTAMP.dump"

# --- ROTATION POLICY (Keep last 3 backups) ---
RETENTION_COUNT=3
cd /home/hammad/projects/docker-capstone/backups
ls -t masterydb_full_*.dump | tail -n +$((RETENTION_COUNT + 1)) | xargs -r rm --

echo "Current durable backups in host rotation:"
ls -lh masterydb_full_*.dump
