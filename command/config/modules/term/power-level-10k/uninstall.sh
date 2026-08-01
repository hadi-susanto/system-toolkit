#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/powerlevel10k.sh"

readonly __POWERLEVEL10K_SHELL_MODULE_ID="term/power-level-10k"

main() {
    local force=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi

    if ! uninstall_shell_integration \
        zsh "$__POWERLEVEL10K_SHELL_MODULE_ID" "$force"; then
        log_error "Powerlevel10k state was retained because the Zsh integration could not be removed"

        return 1
    fi

    remove_powerlevel10k_state || return $?
    log_info "Removed Powerlevel10k installation state"
}

main "$@"
