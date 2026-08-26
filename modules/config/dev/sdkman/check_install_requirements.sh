#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_LIB/checks.sh"
source "$CONFIG_MODULE_DIR/lib/sdkman.sh"

main() {
    local install_dir

    if ! install_dir="$(resolve_sdkman_install_dir)"; then
        log_error "SDKMAN_DIR must be an absolute path without line breaks"

        return "$CONFIG_CHECK_BLOCK"
    fi

    if ! sdkman_installation_valid "$install_dir"; then
        log_error "SDKMAN! initialization is missing or unreadable: $install_dir/bin/sdkman-init.sh"
        log_info "Set SDKMAN_DIR to the correct SDKMAN! installation directory"
        log_info "Example: SDKMAN_DIR=/path/to/sdkman syskit-cfg install dev/sdkman"

        return "$CONFIG_CHECK_BLOCK"
    fi

    return "$CONFIG_CHECK_PROCEED"
}

main "$@"
