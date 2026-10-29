#!/usr/bin/env bash
set -e

# Dynamically resolve project root and backups directory regardless of host machine
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/../backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

CONTAINER_BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$CONTAINER_BACKUP_DIR/masterydb_full_$TIMESTAMP.dump"

echo "[$(date)] Starting durable backup inside postgres-db..."

# Execute pg_dump directly targeting the bind-mounted directory inside container
docker exec -t postgres-db pg_dump -U masteryuser -d masterydb -F c -f "$BACKUP_FILE"

echo "[$(date)] Durable backup successfully created on host at: $BACKUP_DIR/masterydb_full_$TIMESTAMP.dump"

# --- ROTATION POLICY (Keep last 3 backups dynamically) ---
RETENTION_COUNT=3
cd "$BACKUP_DIR"
ls -t masterydb_full_*.dump | tail -n +$((RETENTION_COUNT + 1)) | xargs -r rm -- 2>/dev/null || true

echo "Current durable backups in host rotation:"
ls -lh masterydb_full_*.dump
