#!/usr/bin/env bash
# Backs up Takhti Grow:
#   1. Local mirror + snapshot (INCLUDING the upload keystore and ../takhti_grow-secrets)
#      -> /mnt/storage/project_backups/takhti_grow_backup/
#   2. Google Drive (rclone remote "gdrive:"), EXCLUDING keystores, key.properties
#      and service-account keys — signing secrets never go to cloud storage.
#      https://drive.google.com/drive/folders/1GYgU5GjpSa2tlV2iFrdTVcw0UacGgGU_
# Git push to github.com/AwaizFatima08/takhti is done separately.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$(dirname "$SRC")/takhti_grow-secrets"
LOCAL=/mnt/storage/project_backups/takhti_grow_backup
DRIVE_FOLDER_ID=1GYgU5GjpSa2tlV2iFrdTVcw0UacGgGU_
STAMP=$(date +%Y%m%d_%H%M)

EXCLUDES=(--exclude 'build/' --exclude '.dart_tool/' --exclude 'node_modules/'
          --exclude '.gradle/' --exclude '.idea/' --exclude '*.iml' --exclude '.cxx/')

echo "== Local mirror -> $LOCAL/current"
mkdir -p "$LOCAL"
rsync -a --delete "${EXCLUDES[@]}" "$SRC/" "$LOCAL/current/"
[ -d "$SECRETS" ] && rsync -a "$SECRETS/" "$LOCAL/secrets/" && chmod 700 "$LOCAL/secrets"

echo "== Local snapshot archive"
tar -C "$(dirname "$SRC")" -czf "$LOCAL/takhti_grow_${STAMP}.tar.gz" \
  --exclude='*/build' --exclude='*/.dart_tool' --exclude='*/node_modules' --exclude='*/.gradle' \
  "$(basename "$SRC")"
# Keep the 10 newest snapshots.
ls -1t "$LOCAL"/takhti_grow_*.tar.gz | tail -n +11 | xargs -r rm --

AAB="$SRC/build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB" ]; then
  mkdir -p "$LOCAL/release"
  cp "$AAB" "$LOCAL/release/"
fi

echo "== Google Drive (no secrets)"
rclone sync "$SRC" "gdrive:" --drive-root-folder-id "$DRIVE_FOLDER_ID" \
  "${EXCLUDES[@]}" --exclude '.git/**' --exclude '**/key.properties' \
  --exclude '*.jks' --exclude '*.keystore' --exclude 'service-account*.json' --exclude '*-sa.json' \
  --exclude '**/local.properties' --fast-list --transfers 8
if [ -f "$AAB" ]; then
  rclone copy "$AAB" "gdrive:release" --drive-root-folder-id "$DRIVE_FOLDER_ID"
fi
echo "Backup complete ($STAMP)."
