#!/usr/bin/env bash
# Daily local file-storage backup for CineConnect uploads.
# Intended to run from cron after database backup.
set -euo pipefail

: "${STORAGE_ROOT:=/var/www/cineconnect/storage}"
: "${BACKUP_DIR:=/var/backups/cineconnect}"
: "${RETENTION_DAYS:=14}"

if [[ ! -d "$STORAGE_ROOT" ]]; then
  echo "$(date -u +%FT%TZ) storage root not found: $STORAGE_ROOT" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
timestamp=$(date +%Y%m%d-%H%M%S)
dest="$BACKUP_DIR/cineconnect-storage-$timestamp.tar.gz"
tmp_dest="$dest.tmp"

tar -C "$STORAGE_ROOT" -czf "$tmp_dest" .
mv "$tmp_dest" "$dest"
echo "$(date -u +%FT%TZ) storage backup written to $dest ($(du -h "$dest" | cut -f1))"

find "$BACKUP_DIR" -name 'cineconnect-storage-*.tar.gz' -mtime "+$RETENTION_DAYS" -print -delete
