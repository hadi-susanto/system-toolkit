#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/password-asterisks.sh"

__set_password_asterisks() {
    local enabled="$1"
    local source
    local target
    local state=0

    if password_asterisks_state; then
        state=0
    else
        state=$?
    fi

    if (( enabled )); then
        if (( state == 0 )); then
            log_warn "Password asterisks are already enabled"

            return 0
        fi

        if (( state != 1 )); then
            log_error "Password asterisks cannot be enabled from the current sudoers state"

            return 1
        fi

        source="$__PASSWORD_ASTERISKS_DISABLED_FILE"
        target="$__PASSWORD_ASTERISKS_ENABLED_FILE"
    else
        if (( state == 1 )); then
            log_warn "Password asterisks are already disabled"

            return 0
        fi

        if (( state != 0 )); then
            log_error "Password asterisks cannot be disabled from the current sudoers state"

            return 1
        fi

        source="$__PASSWORD_ASTERISKS_ENABLED_FILE"
        target="$__PASSWORD_ASTERISKS_DISABLED_FILE"
    fi

    if ! sudo mv -- "$source" "$target"; then
        log_error "Failed to update the password-feedback sudoers file"

        return 1
    fi

    if (( enabled )); then
        log_info "Enabled password asterisks"
    else
        log_info "Disabled password asterisks"
    fi
}

main() {
    local selected

    while true; do
        printf 'Current Password Asterisks Status:\n----------------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Password Asterisks Configuration:\n--------------------------------' \
                "Enable password asterisks" \
                "Disable password asterisks"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __set_password_asterisks 1 || return $?
                ;;
            2)
                __set_password_asterisks 0 || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
