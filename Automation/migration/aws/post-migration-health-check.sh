#!/usr/bin/env bash
# AWS post-migration health assessment using native AWS CLI APIs.
# Produces Markdown + JSON reports under --report-dir.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
REPORT_DIR="./reports"
TARGET_GROUP_ARNS=""
RDS_INSTANCE_IDS=""
PROFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2 ;;
    --report-dir) REPORT_DIR="$2"; shift 2 ;;
    --target-group-arns) TARGET_GROUP_ARNS="$2"; shift 2 ;;
    --rds-instance-ids) RDS_INSTANCE_IDS="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--region R] [--report-dir DIR] [--target-group-arns ARN1,ARN2] [--rds-instance-ids id1,id2] [--profile NAME]"
      exit 0 ;;
    *) echo "Unknown: $1"; exit 2 ;;
  esac
done

if ! command -v aws &>/dev/null; then
  echo "ERROR: aws CLI required"; exit 2
fi

AWS=(aws --region "$REGION")
if [[ -n "$PROFILE" ]]; then
  AWS+=(--profile "$PROFILE")
fi

mkdir -p "$REPORT_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
REPORT_MD="${REPORT_DIR}/aws-post-migration-${TS}.md"
REPORT_JSON="${REPORT_DIR}/aws-post-migration-${TS}.json"

CRITICAL_FAIL=0
WARN_COUNT=0
PASS_COUNT=0
RESULTS_JSON="[]"

log() { echo "$*"; }

append_result() {
  local name="$1" status="$2" detail="$3"
  case "$status" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    FAIL) CRITICAL_FAIL=$((CRITICAL_FAIL + 1)) ;;
  esac
  if command -v jq &>/dev/null; then
    RESULTS_JSON=$(echo "$RESULTS_JSON" | jq -c --arg n "$name" --arg s "$status" --arg d "$detail" \
      '. + [{name:$n, status:$s, detail:$d}]')
  fi
  echo "| $name | $status | $detail |" >> "$REPORT_MD"
}

{
  echo "# AWS Post-Migration Health Report"
  echo
  echo "- **Generated (UTC):** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- **Region:** $REGION"
  echo "- **Profile:** ${PROFILE:-default}"
  echo
  echo "## Summary"
  echo
  echo "| Check | Status | Detail |"
  echo "|-------|--------|--------|"
} > "$REPORT_MD"

# --- EC2 ---
log "Checking EC2 instances..."
EC2_JSON=$("${AWS[@]}" ec2 describe-instances --output json 2>/dev/null || echo '{"Reservations":[]}')
if command -v jq &>/dev/null; then
  TOTAL=$(echo "$EC2_JSON" | jq '[.Reservations[].Instances[]] | length')
  RUNNING=$(echo "$EC2_JSON" | jq '[.Reservations[].Instances[] | select(.State.Name=="running")] | length')
  STOPPED=$(echo "$EC2_JSON" | jq '[.Reservations[].Instances[] | select(.State.Name=="stopped")] | length')
  IMPAIRED=$(echo "$EC2_JSON" | jq '[.Reservations[].Instances[] | select(.State.Name=="running") | select(.StateReason.Message? != null)] | length' 2>/dev/null || echo 0)
  NOT_RUNNING=$(echo "$EC2_JSON" | jq '[.Reservations[].Instances[] | select(.State.Name!="running" and .State.Name!="stopped")] | length')
  detail="total=$TOTAL running=$RUNNING stopped=$STOPPED other=$NOT_RUNNING"
  if [[ "$NOT_RUNNING" -gt 0 ]]; then
    append_result "EC2 instance states" "FAIL" "$detail (non-running/non-stopped present)"
  elif [[ "$TOTAL" -eq 0 ]]; then
    append_result "EC2 instance states" "WARN" "No instances found in region"
  else
    append_result "EC2 instance states" "PASS" "$detail"
  fi
else
  append_result "EC2 instance states" "WARN" "jq not installed; install jq for detailed EC2 parsing"
fi

# --- Status checks (system/instance status) ---
log "Checking EC2 status checks..."
STATUS_JSON=$("${AWS[@]}" ec2 describe-instance-status --include-all-instances --output json 2>/dev/null || echo '{"InstanceStatuses":[]}')
if command -v jq &>/dev/null; then
  BAD=$(echo "$STATUS_JSON" | jq '[.InstanceStatuses[] | select(.InstanceStatus.Status!="ok" or .SystemStatus.Status!="ok")] | length')
  if [[ "$BAD" -gt 0 ]]; then
    append_result "EC2 status checks" "FAIL" "$BAD instance(s) with impaired system/instance status"
  else
    append_result "EC2 status checks" "PASS" "All reported instances ok (or none)"
  fi
else
  append_result "EC2 status checks" "WARN" "jq required for status parsing"
fi

# --- Target groups ---
if [[ -n "$TARGET_GROUP_ARNS" ]]; then
  IFS=',' read -ra TG_ARNS <<< "$TARGET_GROUP_ARNS"
  for arn in "${TG_ARNS[@]}"; do
    arn=$(echo "$arn" | xargs)
    [[ -z "$arn" ]] && continue
    log "Checking target group $arn..."
    TH=$("${AWS[@]}" elbv2 describe-target-health --target-group-arn "$arn" --output json 2>/dev/null || echo '{}')
    if command -v jq &>/dev/null; then
      UNHEALTHY=$(echo "$TH" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State!="healthy")] | length')
      TOTAL_T=$(echo "$TH" | jq '[.TargetHealthDescriptions[]] | length')
      if [[ "$UNHEALTHY" -gt 0 ]]; then
        append_result "ALB/NLB targets $(basename "$arn")" "FAIL" "$UNHEALTHY/$TOTAL_T not healthy"
      else
        append_result "ALB/NLB targets $(basename "$arn")" "PASS" "$TOTAL_T healthy"
      fi
    else
      append_result "ALB/NLB targets" "WARN" "jq required"
    fi
  done
else
  append_result "ALB/NLB targets" "WARN" "Skipped (pass --target-group-arns)"
fi

# --- RDS ---
if [[ -n "$RDS_INSTANCE_IDS" ]]; then
  IFS=',' read -ra RIDS <<< "$RDS_INSTANCE_IDS"
  for rid in "${RIDS[@]}"; do
    rid=$(echo "$rid" | xargs)
    [[ -z "$rid" ]] && continue
    log "Checking RDS $rid..."
    RJ=$("${AWS[@]}" rds describe-db-instances --db-instance-identifier "$rid" --output json 2>/dev/null || echo '{}')
    if command -v jq &>/dev/null; then
      ST=$(echo "$RJ" | jq -r '.DBInstances[0].DBInstanceStatus // "unknown"')
      if [[ "$ST" == "available" ]]; then
        append_result "RDS $rid" "PASS" "status=$ST"
      else
        append_result "RDS $rid" "FAIL" "status=$ST"
      fi
    else
      append_result "RDS $rid" "WARN" "jq required"
    fi
  done
else
  append_result "RDS" "WARN" "Skipped (pass --rds-instance-ids)"
fi

# --- CloudWatch alarms ---
log "Checking CloudWatch alarms in ALARM state..."
ALARMS=$("${AWS[@]}" cloudwatch describe-alarms --state-value ALARM --output json 2>/dev/null || echo '{"MetricAlarms":[]}')
if command -v jq &>/dev/null; then
  AC=$(echo "$ALARMS" | jq '.MetricAlarms | length')
  if [[ "$AC" -gt 0 ]]; then
    NAMES=$(echo "$ALARMS" | jq -r '[.MetricAlarms[].AlarmName] | join(", ")' | cut -c1-120)
    append_result "CloudWatch ALARM state" "FAIL" "$AC alarm(s): $NAMES"
  else
    append_result "CloudWatch ALARM state" "PASS" "No alarms in ALARM state"
  fi
else
  append_result "CloudWatch alarms" "WARN" "jq required"
fi

# Footer + JSON
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
  echo "Validate cutover against **Application Migration Service (MGN)**, **DMS**, and **Migration Hub** consoles as applicable."
  echo "This report is a post-migration operational health snapshot, not a full Well-Architected review."
  echo
  echo "## Files"
  echo
  echo "- Markdown: \`$REPORT_MD\`"
  echo "- JSON: \`$REPORT_JSON\`"
} >> "$REPORT_MD"

if command -v jq &>/dev/null; then
  jq -n \
    --arg ts "$TS" \
    --arg region "$REGION" \
    --argjson pass "$PASS_COUNT" \
    --argjson warn "$WARN_COUNT" \
    --argjson fail "$CRITICAL_FAIL" \
    --argjson results "$RESULTS_JSON" \
    '{timestamp:$ts, cloud:"aws", region:$region, summary:{pass:$pass, warn:$warn, fail:$fail}, results:$results}' \
    > "$REPORT_JSON"
else
  echo "{\"timestamp\":\"$TS\",\"cloud\":\"aws\",\"region\":\"$REGION\",\"summary\":{\"pass\":$PASS_COUNT,\"warn\":$WARN_COUNT,\"fail\":$CRITICAL_FAIL}}" > "$REPORT_JSON"
fi

log "Report written: $REPORT_MD"
log "JSON written:   $REPORT_JSON"

if [[ "$CRITICAL_FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
