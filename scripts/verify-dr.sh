#!/usr/bin/env bash
set -e

BACKUP_DIR="/home/hammad/projects/docker-capstone/backups"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/masterydb_full_*.dump 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
  echo "[DR-FAIL] No backups available to verify."
  exit 1
fi

BACKUP_NAME=$(basename "$LATEST_BACKUP")
echo "[DR-START] Verifying integrity of custom dump: $BACKUP_NAME"

# 1. Spin up a temporary isolated Postgres instance for testing
TEMP_CONTAINER="dr-test-db-$(date +%s)"
docker run -d --name "$TEMP_CONTAINER" \
  -e POSTGRES_USER=masteryuser \
  -e POSTGRES_PASSWORD=masterysecretpassword \
  -e POSTGRES_DB=masterydb \
  -v "$BACKUP_DIR":/backups \
  postgres:16-alpine >/dev/null

# 2. Wait for temp database to be ready
echo "Waiting for temporary verification database to initialize..."
until docker exec "$TEMP_CONTAINER" pg_isready -U masteryuser -d masterydb >/dev/null 2>&1; do
  sleep 1
done

# 3. Restore the custom format backup into the temporary container
docker exec "$TEMP_CONTAINER" pg_restore -U masteryuser -d masterydb "/backups/$BACKUP_NAME" >/dev/null 2>&1 || true

# 4. Query the database to verify that our mastery_users table and records exist
RECORD_COUNT=$(docker exec "$TEMP_CONTAINER" psql -U masteryuser -d masterydb -t -c "SELECT count(*) FROM mastery_users;" 2>/dev/null || echo "0")
RECORD_COUNT=$(echo "$RECORD_COUNT" | tr -d '[:space:]')

# 5. Cleanup verification container
docker stop "$TEMP_CONTAINER" >/dev/null
docker rm "$TEMP_CONTAINER" >/dev/null

# 6. Audit Results
if [ "$RECORD_COUNT" -gt 0 ]; then
  echo "[DR-SUCCESS] Disaster Recovery verification passed! Found $RECORD_COUNT records in restored database."
  exit 0
else
  echo "[DR-FAIL] Disaster Recovery verification failed! Table or records could not be verified."
  exit 1
fi
