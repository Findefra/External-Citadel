#!/usr/bin/env bash
# Kubernetes – FreedomPay Application Recovery
set -euo pipefail
NAMESPACE="freedompay"; LOOKBACK="30m"; DRY_RUN=false; LOG_DIR="/var/log/app-error-recovery"
DEPLOYMENTS=("freedompay" "freedompay-worker" "freedompay-queue")
ERROR_PATTERNS="error|exception|fatal|critical|timeout|connection refused|payment|gateway|declined|failed to|ssl|certificate"
while [[ $# -gt 0 ]]; do case "$1" in --namespace|-n) NAMESPACE="$2"; shift 2;; --minutes) LOOKBACK="${2}m"; shift 2;; --dry-run) DRY_RUN=true; shift;; --log-dir) LOG_DIR="$2"; shift 2;; -h|--help) echo "Usage: $0 [--namespace NS] [--minutes N] [--dry-run]"; exit 0;; *) shift;; esac; done
mkdir -p "$LOG_DIR"; LOG_FILE="${LOG_DIR}/k8s-freedompay-recovery-$(date +%Y%m%d).log"
log(){ local l="$1"; shift; local line; line="$(printf '[%s] [%s] %s' "$(date '+%Y-%m-%d %H:%M:%S')" "$l" "$*")"; echo "$line"; echo "$line" >> "$LOG_FILE"; }
has_errors(){ local dep="$1"; kubectl logs -n "$NAMESPACE" -l "app=$dep" --since="$LOOKBACK" --tail=300 2>/dev/null | grep -Eiq "$ERROR_PATTERNS"; }
restart_dep(){ local dep="$1"; if $DRY_RUN; then log "DRY-RUN" "Would rollout restart deployment/$dep"; return; fi; log "INFO" "Rollout restart deployment/$dep"; kubectl rollout restart deployment/"$dep" -n "$NAMESPACE"; kubectl rollout status deployment/"$dep" -n "$NAMESPACE" --timeout=120s && log "INFO" "$dep rollout complete" || log "WARN" "$dep rollout may have issues"; }
log "INFO" "============================================================"; log "INFO" "K8s FreedomPay Recovery started | ns=$NAMESPACE | lookback=$LOOKBACK | dry-run=$DRY_RUN"
RESTARTED=()
for dep in "${DEPLOYMENTS[@]}"; do log "INFO" "Checking: $dep"; if has_errors "$dep"; then log "WARN" "Errors detected in $dep"; restart_dep "$dep"; RESTARTED+=("$dep"); else log "INFO" "No recent errors for $dep"; fi; done
log "INFO" "===== Summary ====="; [[ ${#RESTARTED[@]} -eq 0 ]] && log "INFO" "No rollouts needed" || log "INFO" "Restarted: ${RESTARTED[*]}"
log "INFO" "K8s FreedomPay Recovery finished"; log "INFO" "============================================================"
