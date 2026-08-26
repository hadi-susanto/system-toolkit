#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/sdkman.sh"

readonly __SDKMAN_SHELL_MODULE_ID="dev/sdkman"

main() {
    local failed=0
    local force=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi

    if ! uninstall_shell_integration \
        bash "$__SDKMAN_SHELL_MODULE_ID" "$force"; then
        failed=1
    fi

    if ! uninstall_shell_integration \
        zsh "$__SDKMAN_SHELL_MODULE_ID" "$force"; then
        failed=1
    fi

    if (( failed )); then
        log_error "SDKMAN! state was retained because a shell integration could not be removed"

        return 1
    fi

    remove_sdkman_state || return $?
    log_info "Removed SDKMAN! installation state"
}

main "$@"
