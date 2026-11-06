#!/bin/bash
# 07-git-repo-backup.sh
# Mirror Git repositories and create dated archives
set -euo pipefail

REPOS=(
  "$HOME/projects/infra"
  "$HOME/projects/apps"
  "/opt/git/company-repos"
)
DEST="/backup/git"
DATE=$(date +%Y%m%d)
mkdir -p "$DEST"

for REPO in "${REPOS[@]}"; do
  [[ -d "$REPO" ]] || continue
  NAME=$(basename "$REPO")
  TARGET="$DEST/${NAME}.git"

  if [[ ! -d "$TARGET" ]]; then
    git clone --mirror "$REPO" "$TARGET"
  else
    git -C "$TARGET" remote update --prune
  fi

  tar czf "$DEST/${NAME}_${DATE}.tar.gz" -C "$DEST" "${NAME}.git"
done

find "$DEST" -name "*.tar.gz" -mtime +30 -delete
echo "Git repository backups complete"
