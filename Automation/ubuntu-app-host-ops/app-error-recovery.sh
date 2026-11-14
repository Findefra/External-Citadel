#!/usr/bin/env bash
#
# app-error-recovery.sh  (Ubuntu specialized)
# Scans journalctl / application logs for errors and restarts the systemd
# service plus any defined dependent services.
#
# Optimized for Ubuntu 20.04 / 22.04 / 24.04 with systemd.
#
# Usage:
#   sudo ./app-error-recovery.sh [--dry-run] [--minutes 30] [service ...]
#
# Examples:
#   sudo ./app-error-recovery.sh --dry-run
#   sudo ./app-error-recovery.sh --minutes 15 payment-api
#

set -euo pipefail

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

LOOKBACK_MINUTES=30

# Case-insensitive error patterns
ERROR_PATTERNS=(
    "error"
    "exception"
    "fatal"
    "critical"
    "panic"
    "traceback"
    "out of memory"
    "connection refused"
    "timeout"
    "failed to"
    "segfault"
    "oom-killer"
)

# primary_service -> comma-separated dependents (systemd unit names without .service)
declare -A SERVICE_DEPS=(
    ["payment-api"]="payment-worker,payment-cache"
    ["order-service"]="order-worker,inventory-sync"
    ["auth-service"]="session-store"
    ["notification-service"]=""
)

# Optional custom log files (in addition to journalctl)
declare -A CUSTOM_LOGS=(
    # ["payment-api"]="/var/log/payment-api/app.log"
)

# ------------------------------------------------------------
# Internals
# ------------------------------------------------------------

DRY_RUN=false
TARGET_SERVICES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)   DRY_RUN=true; shift ;;
        --minutes)   LOOKBACK_MINUTES="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--minutes N] [service ...]"
            exit 0
            ;;
        *) TARGET_SERVICES+=("$1"); shift ;;
    esac
done

if [[ ${#TARGET_SERVICES[@]} -eq 0 ]]; then
    TARGET_SERVICES=("${!SERVICE_DEPS[@]}")
fi

log() {
    local level="$1"; shift
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*"
}

has_errors() {
    local service="$1"
    local since="${LOOKBACK_MINUTES} min ago"
    local patterns
    patterns=$(IFS='|'; echo "${ERROR_PATTERNS[*]}")

    # Prefer journalctl (Ubuntu systemd)
    if journalctl -u "${service}.service" --since "$since" --no-pager -q 2>/dev/null | \
       grep -Eiq "$patterns"; then
        return 0
    fi

    # Fallback: custom log file
    if [[ -n "${CUSTOM_LOGS[$service]:-}" && -f "${CUSTOM_LOGS[$service]}" ]]; then
        if grep -Eiq "$patterns" "${CUSTOM_LOGS[$service]}"; then
            return 0
        fi
    fi

    return 1
}

service_active() {
    systemctl is-active --quiet "${1}.service" 2>/dev/null
}

restart_svc() {
    local svc="$1"

    if $DRY_RUN; then
        log "DRY-RUN" "Would restart: ${svc}.service"
        return
    fi

    log "INFO" "Restarting ${svc}.service"
    if systemctl restart "${svc}.service"; then
        sleep 2
        if service_active "$svc"; then
            log "INFO" "${svc}.service is active"
        else
            log "WARN" "${svc}.service failed to become active"
        fi
    else
        log "ERROR" "Failed to restart ${svc}.service"
        return 1
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

log "INFO" "Ubuntu App Error Recovery starting (lookback=${LOOKBACK_MINUTES}m)"
$DRY_RUN && log "INFO" "DRY-RUN mode – no changes will be made"

RESTARTED=()

for service in "${TARGET_SERVICES[@]}"; do
    if [[ -z "${SERVICE_DEPS[$service]+x}" ]]; then
        log "WARN" "'$service' not defined in SERVICE_DEPS – skipping"
        continue
    fi

    log "INFO" "Checking: $service"

    if has_errors "$service"; then
        log "WARN" "Errors detected for $service"

        restart_svc "$service"
        RESTARTED+=("$service")

        deps="${SERVICE_DEPS[$service]}"
        if [[ -n "$deps" ]]; then
            IFS=',' read -ra DEP_ARRAY <<< "$deps"
            for dep in "${DEP_ARRAY[@]}"; do
                dep=$(echo "$dep" | xargs)
                [[ -z "$dep" ]] && continue
                log "INFO" "Restarting dependent: $dep"
                restart_svc "$dep"
                RESTARTED+=("$dep")
            done
        fi
    else
        log "INFO" "No recent errors for $service"
    fi
done

echo
log "INFO" "===== Recovery Summary ====="
if [[ ${#RESTARTED[@]} -eq 0 ]]; then
    log "INFO" "No services required a restart"
else
    log "INFO" "Services restarted: ${RESTARTED[*]}"
fi

$DRY_RUN && log "INFO" "Dry-run complete. Re-run without --dry-run to apply."

exit 0
