#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/powerlevel10k.sh"

readonly __POWERLEVEL10K_SHELL_MODULE_ID="term/power-level-10k"

__uninstall_zsh_integration() {
    if ! run_syskit_bin \
        syskit-zsh uninstall "$__POWERLEVEL10K_SHELL_MODULE_ID"; then
        log_error "Failed to uninstall Powerlevel10k integration for Zsh"

        return 1
    fi
}

main() {
    if ! __uninstall_zsh_integration; then
        log_error "Powerlevel10k state was retained because the Zsh integration could not be removed"

        return 1
    fi

    remove_powerlevel10k_state || return $?
    log_info "Removed Powerlevel10k installation state"
}

main "$@"
