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

##
# __unload_kvm
#
# Unloads the loaded KVM modules for the current boot only. Makes no
# persistent change.
#
# Returns:
#   1 when a module could not be unloaded.
#
__unload_kvm() {
    local module
    local loaded=0
    local failed=0

    for module in "${__KVM_MODULES[@]}"; do
        if grep -q "^$module " /proc/modules 2>/dev/null; then
            loaded=1
        fi
    done

    if (( ! loaded )); then
        log_warn "No KVM modules are loaded"

        return 0
    fi

    log_info "Administrator privileges are required to unload KVM modules"

    for module in "${__KVM_MODULES[@]}"; do
        if ! grep -q "^$module " /proc/modules 2>/dev/null; then
            continue
        fi

        if ! sudo modprobe -r "$module"; then
            log_error "Could not unload $module (still in use?)"
            failed=1
        fi
    done

    if (( failed )); then
        return 1
    fi

    log_info "Unloaded KVM modules (until the next module load or reboot)"
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
        if ! __unload_kvm; then
            log_warn "Autoload stays disabled; KVM modules remain loaded for this boot"
        fi
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
                "Unload KVM modules now (this boot only)" \
                "Enable KVM load at boot" \
                "Disable KVM load at boot"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __unload_kvm || return $?
                ;;
            2)
                __enable_autoload || return $?
                ;;
            3)
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
