#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_DIR="${MIGRATION_ROOT}/reports"
CLOUD=""

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE=""
TG_ARNS=""
RDS_IDS=""
AZ_RG=""
AZ_WEBAPPS=""
AZ_SUB=""
GCP_PROJECT=""
GCP_ZONE=""
GCP_SQL=""
GCP_MIG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud) CLOUD="$2"; shift 2 ;;
    --report-dir) REPORT_DIR="$2"; shift 2 ;;
    --region) AWS_REGION="$2"; shift 2 ;;
    --profile) AWS_PROFILE="$2"; shift 2 ;;
    --target-group-arns) TG_ARNS="$2"; shift 2 ;;
    --rds-instance-ids) RDS_IDS="$2"; shift 2 ;;
    --resource-group) AZ_RG="$2"; shift 2 ;;
    --webapp-names) AZ_WEBAPPS="$2"; shift 2 ;;
    --subscription) AZ_SUB="$2"; shift 2 ;;
    --project) GCP_PROJECT="$2"; shift 2 ;;
    --zone) GCP_ZONE="$2"; shift 2 ;;
    --cloud-sql-instances) GCP_SQL="$2"; shift 2 ;;
    --mig) GCP_MIG="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --cloud aws|azure|gcp [cloud-specific options]"
      exit 0
      ;;
    *) echo "Unknown: $1"; exit 2 ;;
  esac
done

if [[ -z "$CLOUD" ]]; then
  echo "ERROR: --cloud is required"
  exit 2
fi

mkdir -p "$REPORT_DIR"
echo "==> Post-apply validation | cloud=$CLOUD | reports=$REPORT_DIR"

case "$CLOUD" in
  aws)
    ARGS=(--region "$AWS_REGION" --report-dir "$REPORT_DIR")
    [[ -n "$AWS_PROFILE" ]] && ARGS+=(--profile "$AWS_PROFILE")
    [[ -n "$TG_ARNS" ]] && ARGS+=(--target-group-arns "$TG_ARNS")
    [[ -n "$RDS_IDS" ]] && ARGS+=(--rds-instance-ids "$RDS_IDS")
    exec "$MIGRATION_ROOT/aws/post-migration-health-check.sh" "${ARGS[@]}"
    ;;
  azure)
    [[ -z "$AZ_RG" ]] && { echo "ERROR: --resource-group required"; exit 2; }
    ARGS=(--resource-group "$AZ_RG" --report-dir "$REPORT_DIR")
    [[ -n "$AZ_WEBAPPS" ]] && ARGS+=(--webapp-names "$AZ_WEBAPPS")
    [[ -n "$AZ_SUB" ]] && ARGS+=(--subscription "$AZ_SUB")
    exec "$MIGRATION_ROOT/azure/post-migration-health-check.sh" "${ARGS[@]}"
    ;;
  gcp)
    [[ -z "$GCP_PROJECT" || -z "$GCP_ZONE" ]] && { echo "ERROR: --project and --zone required"; exit 2; }
    ARGS=(--project "$GCP_PROJECT" --zone "$GCP_ZONE" --report-dir "$REPORT_DIR")
    [[ -n "$GCP_SQL" ]] && ARGS+=(--cloud-sql-instances "$GCP_SQL")
    [[ -n "$GCP_MIG" ]] && ARGS+=(--mig "$GCP_MIG")
    exec "$MIGRATION_ROOT/gcp/post-migration-health-check.sh" "${ARGS[@]}"
    ;;
  *)
    echo "ERROR: unsupported cloud: $CLOUD"
    exit 2
    ;;
esac
