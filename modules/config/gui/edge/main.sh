#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__set_edge_cron() {
    local enabled="$1"
    local mode
    local target_state
    local word
    local channel
    local path
    local state
    local changed=0
    local failed=0

    if (( enabled )); then
        mode="755"
        target_state=0
        word="enabled"
    else
        mode="644"
        target_state=1
        word="disabled"
    fi

    for channel in "${__EDGE_CHANNELS[@]}"; do
        path="$(edge_cron_path "$channel")"

        if edge_cron_state "$path"; then
            state=0
        else
            state=$?
        fi

        case "$state" in
            2)
                continue
                ;;
            3)
                log_error "[$channel] Unexpected file type, skipping: $path"
                failed=1
                continue
                ;;
        esac

        if (( state == target_state )); then
            log_warn "[$channel] Cron job is already $word"

            continue
        fi

        if sudo chmod "$mode" -- "$path"; then
            changed=1
        else
            log_error "[$channel] Failed to change permissions: $path"
            failed=1
        fi
    done

    if (( failed )); then
        return 1
    fi

    if (( ! changed )); then
        log_warn "No Microsoft Edge cron jobs were changed"

        return 0
    fi

    if (( enabled )); then
        log_info "Enabled Microsoft Edge cron jobs"
    else
        log_info "Disabled Microsoft Edge cron jobs"
    fi
}

main() {
    local selected

    while true; do
        printf 'Current Microsoft Edge Cron Status:\n-----------------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Microsoft Edge Cron Configuration:\n---------------------------------' \
                "Enable Microsoft Edge cron jobs" \
                "Disable Microsoft Edge cron jobs"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __set_edge_cron 1 || return $?
                ;;
            2)
                __set_edge_cron 0 || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
