#!/usr/bin/env bash
#
# app-error-recovery.sh
# Scans application logs for errors and restarts the service + defined dependents.
#
# Usage:
#   ./app-error-recovery.sh [--dry-run] [--minutes 30] [service1 service2 ...]
#
# Examples:
#   ./app-error-recovery.sh                    # Check all defined services
#   ./app-error-recovery.sh payment-api        # Check only payment-api
#   ./app-error-recovery.sh --dry-run          # Show what would be done
#   ./app-error-recovery.sh --minutes 15       # Look at last 15 minutes of logs
#

set -euo pipefail

# ------------------------------------------------------------
# CONFIGURATION - Edit this section for your environment
# ------------------------------------------------------------

# How far back to look in the logs (minutes)
LOOKBACK_MINUTES=30

# Error patterns (case-insensitive). Add/remove as needed.
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
)

# Services to monitor and their dependent services.
# Format:  "primary_service:dep1,dep2,dep3"
# Leave the dependency list empty if none.
declare -A SERVICE_DEPS=(
    ["payment-api"]="payment-worker,payment-cache"
    ["order-service"]="order-worker,inventory-sync"
    ["auth-service"]="session-store"
    ["notification-service"]=""
    # Add more applications here
)

# Optional: absolute path to a custom log file (if not using journalctl)
# Leave empty to use journalctl (recommended)
declare -A CUSTOM_LOGS=(
    # ["payment-api"]="/var/log/payment-api/app.log"
)

# ------------------------------------------------------------
# Script internals
# ------------------------------------------------------------

DRY_RUN=false
TARGET_SERVICES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --minutes)
            LOOKBACK_MINUTES="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--minutes N] [service ...]"
            exit 0
            ;;
        *)
            TARGET_SERVICES+=("$1")
            shift
            ;;
    esac
done

# If no services specified on CLI, use all configured ones
if [[ ${#TARGET_SERVICES[@]} -eq 0 ]]; then
    TARGET_SERVICES=("${!SERVICE_DEPS[@]}")
fi

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

has_errors() {
    local service="$1"
    local since="$(( LOOKBACK_MINUTES * 60 )) seconds ago"
    local patterns
    patterns=$(IFS='|'; echo "${ERROR_PATTERNS[*]}")

    if [[ -n "${CUSTOM_LOGS[$service]:-}" && -f "${CUSTOM_LOGS[$service]}" ]]; then
        # Custom log file
        if grep -Eiq "$patterns" "${CUSTOM_LOGS[$service]}"; then
            return 0
        fi
    else
        # Prefer journalctl (systemd)
        if journalctl -u "$service" --since "$since" --no-pager 2>/dev/null | \
           grep -Eiq "$patterns"; then
            return 0
        fi
    fi
    return 1
}

service_is_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

restart_service() {
    local svc="$1"

    if $DRY_RUN; then
        log "DRY-RUN" "Would restart: $svc"
        return
    fi

    log "INFO" "Restarting service: $svc"
    if systemctl restart "$svc"; then
        log "INFO" "Successfully restarted $svc"
        # Give it a moment to come up
        sleep 2
        if service_is_active "$svc"; then
            log "INFO" "$svc is active after restart"
        else
            log "WARN" "$svc failed to become active after restart"
        fi
    else
        log "ERROR" "Failed to restart $svc"
        return 1
    fi
}

# ------------------------------------------------------------
# Main logic
# ------------------------------------------------------------

log "INFO" "Starting application error recovery scan (lookback: ${LOOKBACK_MINUTES}m)"
if $DRY_RUN; then
    log "INFO" "Running in DRY-RUN mode – no changes will be made"
fi

RESTARTED=()

for service in "${TARGET_SERVICES[@]}"; do
    if [[ -z "${SERVICE_DEPS[$service]+x}" ]]; then
        log "WARN" "Service '$service' is not defined in SERVICE_DEPS – skipping"
        continue
    fi

    log "INFO" "Checking logs for: $service"

    if has_errors "$service"; then
        log "WARN" "Errors detected in $service logs"

        # Restart the primary service first
        restart_service "$service"
        RESTARTED+=("$service")

        # Restart dependents (if any)
        deps="${SERVICE_DEPS[$service]}"
        if [[ -n "$deps" ]]; then
            IFS=',' read -ra DEP_ARRAY <<< "$deps"
            for dep in "${DEP_ARRAY[@]}"; do
                dep=$(echo "$dep" | xargs)   # trim whitespace
                if [[ -n "$dep" ]]; then
                    log "INFO" "Restarting dependent service of $service: $dep"
                    restart_service "$dep"
                    RESTARTED+=("$dep")
                fi
            done
        fi
    else
        log "INFO" "No recent errors found for $service"
    fi
done

# Summary
echo
log "INFO" "===== Recovery Summary ====="
if [[ ${#RESTARTED[@]} -eq 0 ]]; then
    log "INFO" "No services required a restart"
else
    log "INFO" "Services restarted: ${RESTARTED[*]}"
fi

if $DRY_RUN; then
    log "INFO" "Dry-run complete. Re-run without --dry-run to apply changes."
fi

exit 0
