#!/usr/bin/env bash
#
# SVB TLZ Terraform Enterprise - In-Place Patching Rollout Script
# ASG: svb-tlz-terraform-enterprise
# Target Group: svb-tlz-tfe-443
#
# Purpose: Safe monthly in-place patching by temporarily scaling the ASG
# from 2 → 4 healthy instances, then scaling back to 2 after verification.
#
# Usage:
#   ./svb-tlz-tfe-patch-rollout.sh [--dry-run] [--region us-west-2]
#
set -euo pipefail

ASG_NAME="svb-tlz-terraform-enterprise"
TARGET_GROUP_NAME="svb-tlz-tfe-443"
REGION="${AWS_REGION:-us-west-2}"
DESIRED_DURING_PATCH=4
DESIRED_FINAL=2
MIN_SIZE=2
MAX_SIZE=4
HEALTHY_TIMEOUT_SECONDS=900
POLL_INTERVAL_SECONDS=30
DRY_RUN=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --dry-run          Show what would be done without making changes
  --region REGION    AWS region (default: us-west-2)
  -h, --help         Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true; shift ;;
    --region)    REGION="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *)           err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

export AWS_DEFAULT_REGION="$REGION"

log "Starting pre-flight checks..."
command -v aws >/dev/null 2>&1 || { err "aws CLI not found"; exit 1; }
command -v jq  >/dev/null 2>&1 || { err "jq not found"; exit 1; }

TG_ARN=$(aws elbv2 describe-target-groups \
  --names "$TARGET_GROUP_NAME" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || true)

if [[ -z "$TG_ARN" || "$TG_ARN" == "None" ]]; then
  err "Could not find Target Group: $TARGET_GROUP_NAME"
  exit 1
fi
ok "Target Group ARN: $TG_ARN"

ASG_INFO=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0]' \
  --output json)

if [[ "$ASG_INFO" == "null" || -z "$ASG_INFO" ]]; then
  err "ASG not found: $ASG_NAME"
  exit 1
fi

CURRENT_DESIRED=$(echo "$ASG_INFO" | jq -r '.DesiredCapacity')
CURRENT_MIN=$(echo "$ASG_INFO" | jq -r '.MinSize')
CURRENT_MAX=$(echo "$ASG_INFO" | jq -r '.MaxSize')
CURRENT_INSTANCES=$(echo "$ASG_INFO" | jq -r '.Instances | length')

ok "ASG found: $ASG_NAME"
log "  Current Desired: $CURRENT_DESIRED | Min: $CURRENT_MIN | Max: $CURRENT_MAX | Instances: $CURRENT_INSTANCES"

get_instance_ids() {
  aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].Instances[].InstanceId' \
    --output text
}

get_healthy_instance_count() {
  local ids
  ids=$(get_instance_ids)
  if [[ -z "$ids" ]]; then
    echo 0
    return
  fi

  local healthy=0
  for id in $ids; do
    local asg_state
    asg_state=$(aws autoscaling describe-auto-scaling-instances \
      --instance-ids "$id" \
      --query 'AutoScalingInstances[0].LifecycleState' \
      --output text 2>/dev/null || echo "Unknown")

    if [[ "$asg_state" != "InService" ]]; then
      continue
    fi

    local tg_state
    tg_state=$(aws elbv2 describe-target-health \
      --target-group-arn "$TG_ARN" \
      --targets Id="$id" \
      --query 'TargetHealthDescriptions[0].TargetHealth.State' \
      --output text 2>/dev/null || echo "unknown")

    if [[ "$tg_state" == "healthy" ]]; then
      ((healthy++)) || true
    fi
  done
  echo "$healthy"
}

wait_for_healthy_count() {
  local required=$1
  local timeout=$2
  local elapsed=0

  log "Waiting for at least $required healthy instances (timeout: ${timeout}s)..."

  while (( elapsed < timeout )); do
    local healthy
    healthy=$(get_healthy_instance_count)
    log "  Healthy instances: $healthy / $required  (elapsed: ${elapsed}s)"

    if (( healthy >= required )); then
      ok "Reached $healthy healthy instances"
      return 0
    fi

    sleep "$POLL_INTERVAL_SECONDS"
    ((elapsed += POLL_INTERVAL_SECONDS)) || true
  done

  err "Timed out waiting for $required healthy instances"
  return 1
}

set_scale_in_protection() {
  local protect=$1
  local ids
  ids=$(get_instance_ids)

  if [[ -z "$ids" ]]; then
    warn "No instances found to set scale-in protection"
    return
  fi

  if $DRY_RUN; then
    log "[DRY-RUN] Would set ScaleInProtected=$protect on: $ids"
    return
  fi

  for id in $ids; do
    aws autoscaling set-instance-protection \
      --auto-scaling-group-name "$ASG_NAME" \
      --instance-ids "$id" \
      --protected-from-scale-in "$protect" >/dev/null
  done
  ok "Scale-in protection set to $protect on all current instances"
}

update_asg_capacity() {
  local desired=$1
  local min=$2
  local max=$3

  if $DRY_RUN; then
    log "[DRY-RUN] Would update ASG capacity → Desired=$desired Min=$min Max=$max"
    return
  fi

  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --desired-capacity "$desired" \
    --min-size "$min" \
    --max-size "$max"

  ok "ASG capacity updated → Desired=$desired | Min=$min | Max=$max"
}

log "============================================================"
log "  SVB TLZ TFE In-Place Patching Rollout"
log "  Region: $REGION | ASG: $ASG_NAME | Dry-run: $DRY_RUN"
log "============================================================"

log "Step 1: Preparing ASG for scale-out..."
update_asg_capacity "$DESIRED_DURING_PATCH" "$MIN_SIZE" "$MAX_SIZE"

log "Step 2: Waiting for $DESIRED_DURING_PATCH healthy instances..."
if ! wait_for_healthy_count "$DESIRED_DURING_PATCH" "$HEALTHY_TIMEOUT_SECONDS"; then
  err "Failed to reach required healthy capacity. Aborting scale-in."
  exit 1
fi

log "Step 3: Enabling scale-in protection on all instances..."
set_scale_in_protection true

log "Step 4: All instances healthy and protected."
if ! $DRY_RUN; then
  read -r -p "Press ENTER to continue with scale-in to $DESIRED_FINAL (or Ctrl+C to abort)..."
fi

log "Step 5: Removing scale-in protection..."
set_scale_in_protection false

log "Step 6: Scaling ASG back to Desired=$DESIRED_FINAL..."
update_asg_capacity "$DESIRED_FINAL" "$MIN_SIZE" "$MAX_SIZE"

log "Step 7: Waiting for final healthy count of $DESIRED_FINAL..."
if ! wait_for_healthy_count "$DESIRED_FINAL" "$HEALTHY_TIMEOUT_SECONDS"; then
  warn "Did not reach exactly $DESIRED_FINAL healthy instances within timeout."
  exit 1
fi

FINAL_HEALTHY=$(get_healthy_instance_count)
FINAL_IDS=$(get_instance_ids)

ok "Rollout completed successfully"
log "  Final healthy instances: $FINAL_HEALTHY"
log "  Remaining instance IDs: $FINAL_IDS"
