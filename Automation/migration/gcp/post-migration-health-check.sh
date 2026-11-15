#!/usr/bin/env bash
# GCP post-migration health assessment (gcloud).
set -euo pipefail

PROJECT=""
ZONE=""
REPORT_DIR="./reports"
CLOUD_SQL_INSTANCES=""
MIG_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --zone) ZONE="$2"; shift 2 ;;
    --report-dir) REPORT_DIR="$2"; shift 2 ;;
    --cloud-sql-instances) CLOUD_SQL_INSTANCES="$2"; shift 2 ;;
    --mig) MIG_NAME="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --project P --zone Z [--cloud-sql-instances i1,i2] [--mig NAME] [--report-dir DIR]"
      exit 0 ;;
    *) echo "Unknown: $1"; exit 2 ;;
  esac
done

if [[ -z "$PROJECT" || -z "$ZONE" ]]; then
  echo "ERROR: --project and --zone required"; exit 2
fi
if ! command -v gcloud &>/dev/null; then
  echo "ERROR: gcloud required"; exit 2
fi

mkdir -p "$REPORT_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
REPORT_MD="${REPORT_DIR}/gcp-post-migration-${TS}.md"
REPORT_JSON="${REPORT_DIR}/gcp-post-migration-${TS}.json"

CRITICAL_FAIL=0
WARN_COUNT=0
PASS_COUNT=0

append_result() {
  local name="$1" status="$2" detail="$3"
  case "$status" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    FAIL) CRITICAL_FAIL=$((CRITICAL_FAIL + 1)) ;;
  esac
  echo "| $name | $status | $detail |" >> "$REPORT_MD"
  echo "CHECK|$status|$name|$detail" >> "${REPORT_JSON}.lines"
}

{
  echo "# GCP Post-Migration Health Report"
  echo
  echo "- **Generated (UTC):** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- **Project:** $PROJECT"
  echo "- **Zone:** $ZONE"
  echo
  echo "## Summary"
  echo
  echo "| Check | Status | Detail |"
  echo "|-------|--------|--------|"
} > "$REPORT_MD"
: > "${REPORT_JSON}.lines"

echo "Checking GCE instances in $ZONE..."
INST_LIST=$(gcloud compute instances list --project "$PROJECT" --zones "$ZONE" --format='value(name,status)' 2>/dev/null || true)
if [[ -z "$INST_LIST" ]]; then
  append_result "GCE instances" "WARN" "No instances in zone or list failed"
else
  while IFS=$'\t' read -r name status; do
    [[ -z "${name:-}" ]] && continue
    if [[ "$status" == "RUNNING" ]]; then
      append_result "GCE $name" "PASS" "status=$status"
    else
      append_result "GCE $name" "FAIL" "status=$status"
    fi
  done <<< "$INST_LIST"
fi

if [[ -n "$MIG_NAME" ]]; then
  echo "Checking MIG $MIG_NAME..."
  # Region vs zone MIG — try zone first
  SIZE=$(gcloud compute instance-groups managed describe "$MIG_NAME" --project "$PROJECT" --zone "$ZONE" --format='value(targetSize)' 2>/dev/null || \
         gcloud compute instance-groups managed describe "$MIG_NAME" --project "$PROJECT" --region "${ZONE%-*}" --format='value(targetSize)' 2>/dev/null || echo "")
  if [[ -n "$SIZE" ]]; then
    append_result "MIG $MIG_NAME" "PASS" "targetSize=$SIZE"
  else
    append_result "MIG $MIG_NAME" "FAIL" "Could not describe MIG"
  fi
else
  append_result "Managed instance group" "WARN" "Skipped (pass --mig)"
fi

if [[ -n "$CLOUD_SQL_INSTANCES" ]]; then
  IFS=',' read -ra SQLS <<< "$CLOUD_SQL_INSTANCES"
  for s in "${SQLS[@]}"; do
    s=$(echo "$s" | xargs)
    [[ -z "$s" ]] && continue
    ST=$(gcloud sql instances describe "$s" --project "$PROJECT" --format='value(state)' 2>/dev/null || echo "MISSING")
    if [[ "$ST" == "RUNNABLE" ]]; then
      append_result "Cloud SQL $s" "PASS" "state=$ST"
    else
      append_result "Cloud SQL $s" "FAIL" "state=$ST"
    fi
  done
else
  append_result "Cloud SQL" "WARN" "Skipped (pass --cloud-sql-instances)"
fi

{
  echo
  echo "## Totals"
  echo
  echo "- PASS: $PASS_COUNT"
  echo "- WARN: $WARN_COUNT"
  echo "- FAIL: $CRITICAL_FAIL"
  echo
  echo "## Native migration context"
  echo
  echo "Align with **Migrate to Virtual Machines** and **Database Migration Service** in Google Cloud console."
  echo "Add Cloud Monitoring uptime checks for application-level validation."
  echo
  echo "## Files"
  echo
  echo "- Markdown: \`$REPORT_MD\`"
  echo "- JSON: \`$REPORT_JSON\`"
} >> "$REPORT_MD"

{
  echo "{"
  echo "  \"timestamp\": \"$TS\","
  echo "  \"cloud\": \"gcp\","
  echo "  \"project\": \"$PROJECT\","
  echo "  \"zone\": \"$ZONE\","
  echo "  \"summary\": { \"pass\": $PASS_COUNT, \"warn\": $WARN_COUNT, \"fail\": $CRITICAL_FAIL },"
  echo "  \"results\": ["
  first=1
  while IFS='|' read -r _ st name detail; do
    [[ -z "${st:-}" ]] && continue
    if [[ $first -eq 0 ]]; then echo ","; fi
    first=0
    echo -n "    {\"name\": \"$name\", \"status\": \"$st\", \"detail\": \"$detail\"}"
  done < "${REPORT_JSON}.lines"
  echo
  echo "  ]"
  echo "}"
} > "$REPORT_JSON"
rm -f "${REPORT_JSON}.lines"

echo "Report written: $REPORT_MD"
echo "JSON written:   $REPORT_JSON"
[[ "$CRITICAL_FAIL" -gt 0 ]] && exit 1
exit 0
