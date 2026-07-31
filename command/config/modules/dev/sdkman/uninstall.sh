#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/sdkman.sh"

readonly __SDKMAN_SHELL_MODULE_ID="dev/sdkman"

__uninstall_shell_integration() {
    local shell="$1"

    if ! run_syskit_bin \
        "syskit-$shell" uninstall "$__SDKMAN_SHELL_MODULE_ID"; then
        log_error "Failed to uninstall SDKMAN! integration for $shell"

        return 1
    fi
}

main() {
    local failed=0

    if ! __uninstall_shell_integration bash; then
        failed=1
    fi

    if ! __uninstall_shell_integration zsh; then
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
