#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__KVM_MODULES=(kvm_intel kvm_amd kvm)

__state() {
    local state=0

    if kvm_autoload_state; then
        state=0
    else
        state=$?
    fi

    printf '%s' "$state"
}

__enable_autoload() {
    local state

    state="$(__state)"

    if (( state == 0 )); then
        log_warn "KVM autoload is already enabled"

        return 0
    fi

    if (( state != 1 )); then
        log_error "Invalid KVM blacklist file: $__KVM_AUTOLOAD_CONF"

        return 1
    fi

    log_info "Administrator privileges are required to remove the KVM blacklist file"

    if ! sudo rm -f -- "$__KVM_AUTOLOAD_CONF"; then
        log_error "Failed to remove $__KVM_AUTOLOAD_CONF"

        return 1
    fi

    log_info "Enabled KVM autoload at boot"
}

__unload_kvm() {
    local module

    log_info "Administrator privileges are required to unload KVM modules"

    for module in "${__KVM_MODULES[@]}"; do
        if grep -q "^$module " /proc/modules 2>/dev/null; then
            if ! sudo modprobe -r "$module"; then
                log_warn "Could not unload $module (still in use?)"
            fi
        fi
    done
}

__disable_autoload() {
    local state

    state="$(__state)"

    if (( state == 1 )); then
        log_warn "KVM autoload is already disabled"

        return 0
    fi

    if (( state != 0 )); then
        log_error "Invalid KVM blacklist file: $__KVM_AUTOLOAD_CONF"

        return 1
    fi

    log_info "Administrator privileges are required to create the KVM blacklist file"

    if ! printf 'blacklist kvm_intel\nblacklist kvm_amd\n' |
        sudo tee -- "$__KVM_AUTOLOAD_CONF" >/dev/null; then
        log_error "Failed to write $__KVM_AUTOLOAD_CONF"

        return 1
    fi

    log_info "Disabled KVM autoload at boot"

    if confirm_action "Unload KVM modules now?"; then
        __unload_kvm
    fi
}

main() {
    local selected

    while true; do
        show_status $'Current KVM Autoload Status:\n---------------------------' \
            bash "$CONFIG_MODULE_DIR/status.sh" || return $?

        if ! selected="$(
            choose_option \
                $'KVM Autoload Configuration:\n----------------------------' \
                "Enable KVM load at boot" \
                "Disable KVM load at boot"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __enable_autoload || return $?
                ;;
            2)
                __disable_autoload || return $?
                ;;
            X)
                return 0
                ;;
        esac

        pause_prompt
    done
}

main "$@"
