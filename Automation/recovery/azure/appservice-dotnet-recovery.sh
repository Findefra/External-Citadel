#!/usr/bin/env bash
# Azure App Service (.NET) remediation – Bash + Azure CLI
# Status, diagnose (log download), restart, restart instance, slot swap
set -euo pipefail

RESOURCE_GROUP=""
WEBAPP_NAME=""
ACTION="diagnose"   # status|diagnose|restart|restart-instance|swap
SLOT=""
INSTANCE_ID=""
DRY_RUN=false
LOG_DIR="/var/log/app-error-recovery"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource-group|-g) RESOURCE_GROUP="$2"; shift 2 ;;
        --name|-n)           WEBAPP_NAME="$2"; shift 2 ;;
        --action)            ACTION="$2"; shift 2 ;;
        --slot)              SLOT="$2"; shift 2 ;;
        --instance-id)       INSTANCE_ID="$2"; shift 2 ;;
        --dry-run)           DRY_RUN=true; shift ;;
        --log-dir)           LOG_DIR="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 -g <rg> -n <webapp> [--action status|diagnose|restart|restart-instance|swap] [--slot staging] [--instance-id ID] [--dry-run]"
            exit 0
            ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

if [[ -z "$RESOURCE_GROUP" || -z "$WEBAPP_NAME" ]]; then
    echo "ERROR: --resource-group and --name are required"
    exit 1
fi

if ! command -v az &>/dev/null; then
    echo "ERROR: Azure CLI (az) is required"
    exit 1
fi

mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/azure-appservice-dotnet-$(date +%Y%m%d).log"

log() {
    local level="$1"; shift
    local line
    line="$(printf '[%s] [%s] %s' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*")"
    echo "$line"
    echo "$line" >> "$LOG_FILE"
}

slot_args() {
    if [[ -n "$SLOT" ]]; then
        echo "--slot $SLOT"
    fi
}

do_status() {
    log "INFO" "Status for $WEBAPP_NAME in $RESOURCE_GROUP"
    # shellcheck disable=SC2046
    az webapp show -g "$RESOURCE_GROUP" -n "$WEBAPP_NAME" $(slot_args) -o jsonc 2>&1 | tee -a "$LOG_FILE"
    log "INFO" "Instances:"
    # shellcheck disable=SC2046
    az webapp list-instances -g "$RESOURCE_GROUP" -n "$WEBAPP_NAME" $(slot_args) -o table 2>&1 | tee -a "$LOG_FILE"
}

do_diagnose() {
    do_status
    local zip="${LOG_DIR}/webapp-logs-${WEBAPP_NAME}.zip"
    if $DRY_RUN; then
        log "DRY-RUN" "Would download logs to $zip"
    else
        log "INFO" "Downloading application logs (if enabled)..."
        # shellcheck disable=SC2046
        if az webapp log download -g "$RESOURCE_GROUP" -n "$WEBAPP_NAME" $(slot_args) --log-file "$zip" 2>&1 | tee -a "$LOG_FILE"; then
            log "INFO" "Logs saved to $zip – review for .NET exceptions / startup failures"
        else
            log "WARN" "Log download failed or not configured. Use Log stream, Kudu, or Application Insights."
        fi
    fi
    log "INFO" "Portal: Diagnose and solve problems | Application Insights | Kudu scm site"
}

do_restart() {
    if $DRY_RUN; then
        log "DRY-RUN" "Would restart $WEBAPP_NAME slot=$SLOT"
        return
    fi
    log "INFO" "Restarting App Service $WEBAPP_NAME..."
    # shellcheck disable=SC2046
    az webapp restart -g "$RESOURCE_GROUP" -n "$WEBAPP_NAME" $(slot_args) 2>&1 | tee -a "$LOG_FILE"
    log "INFO" "Restart requested. Allow cold-start time for .NET."
}

do_restart_instance() {
    if [[ -z "$INSTANCE_ID" ]]; then
        log "ERROR" "--instance-id is required for restart-instance"
        exit 1
    fi
    if $DRY_RUN; then
        log "DRY-RUN" "Would restart instance $INSTANCE_ID"
        return
    fi
    log "INFO" "Restarting instance $INSTANCE_ID..."
    # shellcheck disable=SC2046
    az webapp restart -g "$RESOURCE_GROUP" -n "$WEBAPP_NAME" $(slot_args) --instance-id "$INSTANCE_ID" 2>&1 | tee -a "$LOG_FILE"
}

do_swap() {
    if [[ -z "$SLOT" ]]; then
        log "ERROR" "--slot is required for swap (e.g. staging)"
        exit 1
    fi
    if $DRY_RUN; then
        log "DRY-RUN" "Would swap $SLOT ↔ production on $WEBAPP_NAME"
        return
    fi
    log "INFO" "Swapping slot $SLOT ↔ production..."
    az webapp deployment slot swap -g "$RESOURCE_GROUP" -n "$WEBAPP_NAME" --slot "$SLOT" --target-slot production 2>&1 | tee -a "$LOG_FILE"
    log "INFO" "Slot swap finished (check exit status above)."
}

log "INFO" "============================================================"
log "INFO" "Azure App Service .NET recovery | app=$WEBAPP_NAME | rg=$RESOURCE_GROUP | action=$ACTION | dry-run=$DRY_RUN"
log "INFO" "Log file: $LOG_FILE"

case "$ACTION" in
    status)           do_status ;;
    diagnose)         do_diagnose ;;
    restart)          do_restart ;;
    restart-instance) do_restart_instance ;;
    swap)             do_swap ;;
    *) log "ERROR" "Unknown action: $ACTION"; exit 1 ;;
esac

log "INFO" "Azure App Service .NET recovery finished"
log "INFO" "============================================================"
