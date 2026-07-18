#!/usr/bin/env bash
# Daily MySQL backup for the CineConnect production database.
# Credentials are supplied via environment variables (never hardcoded here).
# Intended to run from cron as: 0 2 * * * /path/to/backup_db.sh >> /var/log/cineconnect-backup.log 2>&1
set -euo pipefail

: "${MYSQL_HOST:=127.0.0.1}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${BACKUP_DIR:=/var/backups/cineconnect}"
: "${RETENTION_DAYS:=14}"

mkdir -p "$BACKUP_DIR"
timestamp=$(date +%Y%m%d-%H%M%S)
dest="$BACKUP_DIR/cineconnect-$timestamp.sql.gz"
tmp_dest="$dest.tmp"

mysqldump \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASSWORD" \
  --single-transaction \
  --routines \
  --triggers \
  "$MYSQL_DATABASE" | gzip > "$tmp_dest"

mv "$tmp_dest" "$dest"
echo "$(date -u +%FT%TZ) backup written to $dest ($(du -h "$dest" | cut -f1))"

find "$BACKUP_DIR" -name 'cineconnect-*.sql.gz' -mtime "+$RETENTION_DAYS" -print -delete
