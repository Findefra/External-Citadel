#!/usr/bin/env bash
# Azure post-migration health assessment (Azure CLI).
set -euo pipefail

RESOURCE_GROUP=""
REPORT_DIR="./reports"
WEBAPP_NAMES=""
SUBSCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group|-g) RESOURCE_GROUP="$2"; shift 2 ;;
    --report-dir) REPORT_DIR="$2"; shift 2 ;;
    --webapp-names) WEBAPP_NAMES="$2"; shift 2 ;;
    --subscription) SUBSCRIPTION="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 -g <resource-group> [--webapp-names a,b] [--subscription ID] [--report-dir DIR]"
      exit 0 ;;
    *) echo "Unknown: $1"; exit 2 ;;
  esac
done

if [[ -z "$RESOURCE_GROUP" ]]; then
  echo "ERROR: --resource-group required"; exit 2
fi
if ! command -v az &>/dev/null; then
  echo "ERROR: az CLI required"; exit 2
fi

if [[ -n "$SUBSCRIPTION" ]]; then
  az account set --subscription "$SUBSCRIPTION"
fi

mkdir -p "$REPORT_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
REPORT_MD="${REPORT_DIR}/azure-post-migration-${TS}.md"
REPORT_JSON="${REPORT_DIR}/azure-post-migration-${TS}.json"

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
  echo "# Azure Post-Migration Health Report"
  echo
  echo "- **Generated (UTC):** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- **Resource group:** $RESOURCE_GROUP"
  echo "- **Subscription:** $(az account show --query id -o tsv 2>/dev/null || echo unknown)"
  echo
  echo "## Summary"
  echo
  echo "| Check | Status | Detail |"
  echo "|-------|--------|--------|"
} > "$REPORT_MD"
: > "${REPORT_JSON}.lines"

echo "Checking VMs in $RESOURCE_GROUP..."
VM_LIST=$(az vm list -g "$RESOURCE_GROUP" -o json 2>/dev/null || echo '[]')
VM_COUNT=$(echo "$VM_LIST" | grep -c '"name"' || true)
if [[ "$VM_COUNT" -eq 0 ]]; then
  append_result "Virtual machines" "WARN" "No VMs in resource group"
else
  # Power state via list with show-details is heavy; use instance view per VM names
  NAMES=$(az vm list -g "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || true)
  BAD=0
  TOTAL=0
  while IFS= read -r vm; do
    [[ -z "$vm" ]] && continue
    TOTAL=$((TOTAL + 1))
    POWER=$(az vm get-instance-view -g "$RESOURCE_GROUP" -n "$vm" --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv 2>/dev/null || echo "Unknown")
    if [[ "$POWER" != "VM running" ]]; then
      BAD=$((BAD + 1))
      append_result "VM $vm" "FAIL" "power=$POWER"
    else
      append_result "VM $vm" "PASS" "power=$POWER"
    fi
  done <<< "$NAMES"
  if [[ "$TOTAL" -eq 0 ]]; then
    append_result "Virtual machines" "WARN" "Could not enumerate VM names"
  fi
fi

if [[ -n "$WEBAPP_NAMES" ]]; then
  IFS=',' read -ra APPS <<< "$WEBAPP_NAMES"
  for app in "${APPS[@]}"; do
    app=$(echo "$app" | xargs)
    [[ -z "$app" ]] && continue
    STATE=$(az webapp show -g "$RESOURCE_GROUP" -n "$app" --query state -o tsv 2>/dev/null || echo "Missing")
    if [[ "$STATE" == "Running" ]]; then
      append_result "App Service $app" "PASS" "state=$STATE"
    else
      append_result "App Service $app" "FAIL" "state=$STATE"
    fi
  done
else
  append_result "App Service" "WARN" "Skipped (pass --webapp-names)"
fi

echo "Checking SQL servers in RG..."
SQL_COUNT=$(az sql server list -g "$RESOURCE_GROUP" --query "length(@)" -o tsv 2>/dev/null || echo 0)
if [[ "$SQL_COUNT" -gt 0 ]]; then
  append_result "Azure SQL servers" "PASS" "count=$SQL_COUNT in RG"
else
  append_result "Azure SQL servers" "WARN" "None in RG (OK if not used)"
fi

echo "Sampling activity log errors (last 1h)..."
# May require permission; non-fatal
ERRS=$(az monitor activity-log list --resource-group "$RESOURCE_GROUP" --offset 1h --query "[?level=='Error'] | length(@)" -o tsv 2>/dev/null || echo "n/a")
if [[ "$ERRS" == "n/a" ]]; then
  append_result "Activity log errors (1h)" "WARN" "Could not query activity log"
elif [[ "$ERRS" -gt 0 ]]; then
  append_result "Activity log errors (1h)" "FAIL" "error events=$ERRS"
else
  append_result "Activity log errors (1h)" "PASS" "No Error-level events in sample"
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
  echo "Align with **Azure Migrate**, **Azure Site Recovery**, and **Azure Database Migration Service** project status."
  echo "Use App Service health endpoints (/health/ready) and Azure Monitor after web cutovers."
  echo
  echo "## Files"
  echo
  echo "- Markdown: \`$REPORT_MD\`"
  echo "- JSON: \`$REPORT_JSON\`"
} >> "$REPORT_MD"

# Simple JSON without requiring jq
{
  echo "{"
  echo "  \"timestamp\": \"$TS\","
  echo "  \"cloud\": \"azure\","
  echo "  \"resourceGroup\": \"$RESOURCE_GROUP\","
  echo "  \"summary\": { \"pass\": $PASS_COUNT, \"warn\": $WARN_COUNT, \"fail\": $CRITICAL_FAIL },"
  echo "  \"results\": ["
  first=1
  while IFS='|' read -r _ st name detail; do
    [[ -z "${st:-}" ]] && continue
    if [[ $first -eq 0 ]]; then echo ","; fi
    first=0
    name_esc=${name//\"/\"}
    detail_esc=${detail//\"/\"}
    echo -n "    {\"name\": \"$name_esc\", \"status\": \"$st\", \"detail\": \"$detail_esc\"}"
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
