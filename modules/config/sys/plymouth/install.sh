#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/plymouth.sh"

__set_plymouth() {
    local enabled="$1"
    local expected_state
    local replacement
    local search
    local state

    if plymouth_state; then
        state=0
    else
        state=$?
    fi

    if (( enabled )); then
        if (( state == 0 )); then
            log_warn "Plymouth is already enabled"

            return 0
        fi

        expected_state=1
        search='^GRUB_CMDLINE_LINUX_DEFAULT=""$'
        replacement='GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"'
    else
        if (( state == 1 )); then
            log_warn "Plymouth is already disabled"

            return 0
        fi

        expected_state=0
        search='^GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"$'
        replacement='GRUB_CMDLINE_LINUX_DEFAULT=""'
    fi

    if (( state != expected_state )); then
        log_error "Plymouth cannot be changed from the current GRUB configuration"

        return 1
    fi

    if ! sudo sed -i "s|$search|$replacement|" "$__PLYMOUTH_GRUB_FILE"; then
        log_error "Failed to update the GRUB Plymouth configuration"

        return 1
    fi

    if ! sudo update-grub; then
        log_error "Plymouth was changed, but the GRUB configuration could not be regenerated"

        return 1
    fi

    if (( enabled )); then
        log_info "Enabled Plymouth and regenerated the GRUB configuration"
    else
        log_info "Disabled Plymouth and regenerated the GRUB configuration"
    fi
}

main() {
    local selected

    while true; do
        printf 'Current Plymouth Status:\n------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Plymouth Configuration:\n----------------------' \
                "Enable Plymouth splash" \
                "Disable Plymouth splash (verbose boot)"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __set_plymouth 1 || return $?
                ;;
            2)
                __set_plymouth 0 || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
