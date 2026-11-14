#!/usr/bin/env bash
# Ubuntu – FreedomPay Application Server Recovery
set -euo pipefail

LOOKBACK_MINUTES=30
LOG_DIR="/var/log/app-error-recovery"
DRY_RUN=false

ERROR_PATTERNS=("error" "exception" "fatal" "critical" "timeout" "connection refused" "payment" "gateway" "declined" "failed to" "ssl" "certificate")

declare -A SERVICE_DEPS=(
    ["freedompay"]="freedompay-worker,freedompay-queue"
    ["freedompay-worker"]=""
    ["freedompay-queue"]=""
)

declare -A CUSTOM_LOGS=(
    ["freedompay"]="/opt/freedompay/logs/freedompay.log"
)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --minutes) LOOKBACK_MINUTES="$2"; shift 2 ;;
        --log-dir) LOG_DIR="$2"; shift 2 ;;
        -h|--help) echo "Usage: $0 [--dry-run] [--minutes N] [--log-dir DIR]"; exit 0 ;;
        *) shift ;;
    esac
done

mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/freedompay-recovery-$(date +%Y%m%d).log"
log() { local l="$1"; shift; local line; line="$(printf '[%s] [%s] %s' "$(date '+%Y-%m-%d %H:%M:%S')" "$l" "$*")"; echo "$line"; echo "$line" >> "$LOG_FILE"; }

has_errors() {
    local s="$1" patterns; patterns=$(IFS='|'; echo "${ERROR_PATTERNS[*]}")
    journalctl -u "${s}.service" --since "${LOOKBACK_MINUTES} min ago" --no-pager -q 2>/dev/null | grep -Eiq "$patterns" && return 0
    [[ -n "${CUSTOM_LOGS[$s]:-}" && -f "${CUSTOM_LOGS[$s]}" ]] && grep -Eiq "$patterns" "${CUSTOM_LOGS[$s]}" && return 0
    return 1
}

restart_svc() {
    local s="$1"
    if $DRY_RUN; then log "DRY-RUN" "Would restart ${s}.service"; return; fi
    log "INFO" "Restarting ${s}.service"
    systemctl restart "${s}.service" && sleep 2
    systemctl is-active --quiet "${s}.service" && log "INFO" "${s}.service active" || log "WARN" "${s}.service not active"
}

log "INFO" "============================================================"
log "INFO" "Ubuntu FreedomPay Recovery started | log=$LOG_FILE | lookback=${LOOKBACK_MINUTES}m | dry-run=$DRY_RUN"

RESTARTED=()
for svc in "${!SERVICE_DEPS[@]}"; do
    log "INFO" "Checking: $svc"
    if has_errors "$svc"; then
        log "WARN" "Errors detected for $svc"
        restart_svc "$svc"; RESTARTED+=("$svc")
        IFS=',' read -ra deps <<< "${SERVICE_DEPS[$svc]}"
        for d in "${deps[@]}"; do d=$(echo "$d" | xargs); [[ -z "$d" ]] && continue
            log "INFO" "Restarting dependent: $d"; restart_svc "$d"; RESTARTED+=("$d")
        done
    else log "INFO" "No recent errors for $svc"; fi
done

log "INFO" "===== Summary ====="
[[ ${#RESTARTED[@]} -eq 0 ]] && log "INFO" "No restarts needed" || log "INFO" "Restarted: ${RESTARTED[*]}"
log "INFO" "Ubuntu FreedomPay Recovery finished"
log "INFO" "============================================================"
