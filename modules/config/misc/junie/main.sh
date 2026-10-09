#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__configure_junie_auto_update() {
    local state="$1"
    local confirmation_status

    printf 'The following Junie configuration changes will be applied:\n  auto-update = %s\n' \
        "$state" >&2

    if confirm_action "Apply these changes?"; then
        :
    else
        confirmation_status=$?

        if (( confirmation_status == 1 )); then
            log_info "Junie configuration changes were cancelled"

            return 0
        fi

        return "$confirmation_status"
    fi

    if ! write_junie_auto_update_state "$state"; then
        log_error "Failed to update the Junie configuration"

        return 1
    fi

    log_info "Updated Junie configuration: auto-update = $state"
}

main() {
    local selected

    while true; do
        printf 'Current Junie Status:\n---------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Junie Configuration:\n---------------------' \
                "Enable Auto Update (auto-update = true)" \
                "Disable Auto Update (auto-update = false)"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __configure_junie_auto_update "true" || return $?
                ;;
            2)
                __configure_junie_auto_update "false" || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
