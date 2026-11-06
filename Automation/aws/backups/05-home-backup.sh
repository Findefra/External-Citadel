#!/bin/bash
# 05-home-backup.sh
# Backup user home directory with common exclusions
set -euo pipefail

USER_HOME="${HOME}"
DEST="/backup/homes/$(whoami)/$(date +%Y-%m-%d)"
mkdir -p "$DEST"

rsync -aAXv --delete \
  --exclude='.cache/' \
  --exclude='.local/share/Trash/' \
  --exclude='node_modules/' \
  --exclude='.npm/' \
  --exclude='*.tmp' \
  --exclude='.vscode-server/' \
  --exclude='.cursor/' \
  --exclude='__pycache__/' \
  "$USER_HOME/" "$DEST/"

echo "Home backup complete: $DEST"
