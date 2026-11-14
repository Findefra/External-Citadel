#!/usr/bin/env bash
# Ubuntu – Nginx Error Recovery
# Scans nginx/journal logs for errors and reloads or restarts nginx (+ optional upstreams)
set -euo pipefail

LOOKBACK_MINUTES=30
LOG_DIR="/var/log/app-error-recovery"
DRY_RUN=false
PREFER_RELOAD=true   # prefer graceful reload over full restart when possible

ERROR_PATTERNS=(
    "error" "emerg" "crit" "alert"
    "connection refused" "upstream timed out" "no live upstreams"
    "SSL_do_handshake" "certificate" "failed ("
    "worker process" "exited" "segfault"
)

# Primary + optional dependent upstream app services
declare -A SERVICE_DEPS=(
    ["nginx"]=""
    # ["nginx"]="mywebapp"   # uncomment/add upstreams if you want them restarted too
)

declare -A CUSTOM_LOGS=(
    ["nginx"]="/var/log/nginx/error.log"
)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)     DRY_RUN=true; shift ;;
        --minutes)     LOOKBACK_MINUTES="$2"; shift 2 ;;
        --log-dir)     LOG_DIR="$2"; shift 2 ;;
        --force-restart) PREFER_RELOAD=false; shift ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--minutes N] [--log-dir DIR] [--force-restart]"
            exit 0
            ;;
        *) shift ;;
    esac
done

mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/nginx-recovery-$(date +%Y%m%d).log"

log() {
    local level="$1"; shift
    local line
    line="$(printf '[%s] [%s] %s' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*")"
    echo "$line"
    echo "$line" >> "$LOG_FILE"
}

has_errors() {
    local service="$1"
    local patterns
    patterns=$(IFS='|'; echo "${ERROR_PATTERNS[*]}")

    if journalctl -u "${service}.service" --since "${LOOKBACK_MINUTES} min ago" --no-pager -q 2>/dev/null | \
       grep -Eiq "$patterns"; then
        return 0
    fi
    if [[ -n "${CUSTOM_LOGS[$service]:-}" && -f "${CUSTOM_LOGS[$service]}" ]]; then
        # Check recent lines only
        if tail -n 500 "${CUSTOM_LOGS[$service]}" | grep -Eiq "$patterns"; then
            return 0
        fi
    fi
    return 1
}

restart_or_reload_nginx() {
    if $DRY_RUN; then
        if $PREFER_RELOAD; then
            log "DRY-RUN" "Would run: nginx -t && systemctl reload nginx"
        else
            log "DRY-RUN" "Would run: systemctl restart nginx"
        fi
        return
    fi

    if $PREFER_RELOAD; then
        log "INFO" "Testing nginx configuration"
        if nginx -t 2>&1 | tee -a "$LOG_FILE" | grep -q "successful"; then
            log "INFO" "Config OK – reloading nginx"
            systemctl reload nginx
            sleep 2
            systemctl is-active --quiet nginx && log "INFO" "nginx is active after reload" || log "WARN" "nginx not active after reload"
        else
            log "WARN" "nginx -t failed – falling back to restart"
            systemctl restart nginx
            sleep 2
            systemctl is-active --quiet nginx && log "INFO" "nginx is active after restart" || log "WARN" "nginx not active after restart"
        fi
    else
        log "INFO" "Force restarting nginx"
        systemctl restart nginx
        sleep 2
        systemctl is-active --quiet nginx && log "INFO" "nginx is active" || log "WARN" "nginx not active"
    fi
}

restart_svc() {
    local svc="$1"
    if [[ "$svc" == "nginx" ]]; then
        restart_or_reload_nginx
        return
    fi
    if $DRY_RUN; then
        log "DRY-RUN" "Would restart ${svc}.service"
        return
    fi
    log "INFO" "Restarting ${svc}.service"
    systemctl restart "${svc}.service" && sleep 2
    systemctl is-active --quiet "${svc}.service" && log "INFO" "${svc}.service active" || log "WARN" "${svc}.service not active"
}

log "INFO" "============================================================"
log "INFO" "Ubuntu Nginx Recovery started | log=$LOG_FILE | lookback=${LOOKBACK_MINUTES}m | dry-run=$DRY_RUN | prefer-reload=$PREFER_RELOAD"

RESTARTED=()

if has_errors "nginx"; then
    log "WARN" "Errors detected for nginx"
    restart_svc "nginx"
    RESTARTED+=("nginx")

    deps="${SERVICE_DEPS[nginx]:-}"
    if [[ -n "$deps" ]]; then
        IFS=',' read -ra DEP_ARRAY <<< "$deps"
        for d in "${DEP_ARRAY[@]}"; do
            d=$(echo "$d" | xargs)
            [[ -z "$d" ]] && continue
            log "INFO" "Restarting dependent: $d"
            restart_svc "$d"
            RESTARTED+=("$d")
        done
    fi
else
    log "INFO" "No recent errors found for nginx"
fi

log "INFO" "===== Recovery Summary ====="
if [[ ${#RESTARTED[@]} -eq 0 ]]; then
    log "INFO" "No services required a restart/reload"
else
    log "INFO" "Actions taken on: ${RESTARTED[*]}"
fi
$DRY_RUN && log "INFO" "Dry-run complete. Re-run without --dry-run to apply."
log "INFO" "Ubuntu Nginx Recovery finished"
log "INFO" "============================================================"
